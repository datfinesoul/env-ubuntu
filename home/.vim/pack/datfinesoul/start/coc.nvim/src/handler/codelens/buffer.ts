import { Neovim } from '@chemzqm/neovim'
import debounce from 'debounce'
import { CancellationTokenSource, CodeLens, Command } from 'vscode-languageserver-protocol'
import { LinesTextDocument } from '../../model/textdocument'
import commandManager from '../../commands'
import languages from '../../languages'
import { BufferSyncItem } from '../../types'
import window from '../../window'
import workspace from '../../workspace'
import Document from '../../model/document'
const logger = require('../../util/logger')('codelens-buffer')

export interface CodeLensInfo {
  codeLenses: CodeLens[]
  version: number
  hasError: boolean
}

export interface CodeLensConfig {
  position: 'top' | 'eol' | 'right_align'
  enabled: boolean
  separator: string
  subseparator: string
}

/**
 * CodeLens buffer
 */
export default class CodeLensBuffer implements BufferSyncItem {
  private codeLenses: CodeLensInfo
  private tokenSource: CancellationTokenSource
  private resolveTokenSource: CancellationTokenSource
  private srcId: number
  public fetchCodelenses: (() => void) & { clear(): void }
  public resolveCodeLens: (() => void) & { clear(): void }
  constructor(
    private nvim: Neovim,
    public readonly bufnr: number,
    private config: CodeLensConfig
  ) {
    this.fetchCodelenses = debounce(() => {
      void this._fetchCodeLenses()
    }, 200)
    this.resolveCodeLens = debounce(() => {
      void this._resolveCodeLenses()
    }, 200)
    this.fetchCodelenses()
  }

  public onChange(): void {
    this.cancel()
    this.fetchCodelenses()
  }

  public currentCodeLens(): CodeLens[] {
    return this.codeLenses?.codeLenses
  }

  private get enabled(): boolean {
    return this.document && this.config.enabled && languages.hasProvider('codeLens', this.document.textDocument)
  }

  public async forceFetch(): Promise<void> {
    this.fetchCodelenses.clear()
    await this._fetchCodeLenses()
  }

  private get document(): Document | undefined {
    return workspace.getDocument(this.bufnr)
  }

  private async _fetchCodeLenses(): Promise<void> {
    if (!this.enabled) return
    this.cancel()
    let noFetch = !this.isChanged && !this.codeLenses?.hasError
    if (!noFetch) {
      let { textDocument } = this.document
      let version = textDocument.version
      let tokenSource = this.tokenSource = new CancellationTokenSource()
      let token = tokenSource.token
      let codeLenses = await languages.getCodeLens(textDocument, token)
      this.tokenSource = undefined
      if (token.isCancellationRequested) return
      if (!Array.isArray(codeLenses) || codeLenses.length == 0) return
      let hasError = codeLenses.some(o => o == null)
      this.codeLenses = { version, codeLenses: codeLenses.filter(o => o != null), hasError }
    }
    let codeLenses = this.codeLenses?.codeLenses
    if (codeLenses?.length) {
      await this._resolveCodeLenses()
    }
  }

  /**
   * Resolve visible codeLens
   */
  private async _resolveCodeLenses(): Promise<void> {
    if (!this.enabled || !this.codeLenses || this.isChanged) return
    let { codeLenses } = this.codeLenses
    let [bufnr, start, end] = await this.nvim.eval(`[bufnr('%'),line('w0'),line('w$')]`) as [number, number, number]
    // only resolve current buffer
    if (this.isChanged || bufnr != this.bufnr) return
    if (this.resolveTokenSource) {
      this.resolveTokenSource.cancel()
    }
    codeLenses = codeLenses.filter(o => {
      let lnum = o.range.start.line + 1
      return lnum >= start && lnum <= end
    })
    if (codeLenses.length) {
      let tokenSource = this.resolveTokenSource = new CancellationTokenSource()
      let token = tokenSource.token
      await Promise.all(codeLenses.map(codeLens => languages.resolveCodeLens(codeLens, token)))
      this.resolveTokenSource = undefined
      if (token.isCancellationRequested || this.isChanged) return
    }
    if (!this.srcId) this.srcId = await this.nvim.createNamespace('coc-codelens')
    this.nvim.pauseNotification()
    this.clear(start - 1, end)
    this.setVirtualText(codeLenses)
    void this.nvim.resumeNotification(false, true)
  }

  private get isChanged(): boolean {
    if (!this.document || !this.codeLenses) return true
    let { version } = this.codeLenses
    return this.document.textDocument.version !== version
  }

  /**
   * Attach resolved codeLens
   */
  private setVirtualText(codeLenses: CodeLens[]): void {
    let { document } = this
    if (!document || !codeLenses.length) return
    let list: Map<number, CodeLens[]> = new Map()
    let { position } = this.config
    for (let codeLens of codeLenses) {
      let { range, command } = codeLens
      if (!command) continue
      let { line } = range.start
      if (list.has(line)) {
        list.get(line).push(codeLens)
      } else {
        list.set(line, [codeLens])
      }
    }
    for (let lnum of list.keys()) {
      let codeLenses = list.get(lnum)
      let commands = codeLenses.map(codeLens => codeLens.command)
      commands = commands.filter(c => c && c.title)
      let chunks: [string, string][] = []
      let n_commands = commands.length
      for (let i = 0; i < n_commands; i++) {
        let c = commands[i]
        chunks.push([c.title.replace(/(\r\n|\r|\n|\s)+/g, " "), 'CocCodeLens'] as [string, string])
        if (i != n_commands - 1) {
          chunks.push([this.config.subseparator, 'CocCodeLens'] as [string, string])
        }
      }
      if (this.config.separator) {
        chunks.unshift([`${this.config.separator} `, 'CocCodeLens'])
      }
      if (workspace.has('nvim-0.6.0')) {
        let buf = this.nvim.createBuffer(this.bufnr)
        if (lnum >= document.lineCount) continue
        let line = document.getline(lnum)
        if (position == 'top') {
          let indent = line.match(/^\s*/)[0]
          if (indent.length > 0) chunks.unshift([indent, 'Normal'])
          buf.setExtMark(this.srcId, lnum, 0, {
            virt_lines: [chunks],
            virt_lines_above: true
          })
        } else {
          buf.setExtMark(this.srcId, lnum, 0, {
            hl_mode: 'combine',
            virt_text: chunks,
            virt_text_pos: position
          })
        }
      } else {
        this.nvim.call('nvim_buf_set_virtual_text', [this.bufnr, this.srcId, lnum, chunks, {}], true)
      }
    }
  }

  public clear(start = 0, end = -1): void {
    if (!this.srcId) return
    let buf = this.nvim.createBuffer(this.bufnr)
    buf.clearNamespace(this.srcId, start, end)
  }

  public cleanUp(): void {
    this.clear()
    this.codeLenses = undefined
  }

  public getCodelenses(): CodeLens[] | undefined {
    return this.codeLenses?.codeLenses
  }

  public async doAction(line: number): Promise<void> {
    let { codeLenses } = this.codeLenses ?? {}
    if (!codeLenses?.length) return
    let commands: Command[] = []
    for (let codeLens of codeLenses) {
      let { range, command } = codeLens
      if (!command || !range) continue
      if (line == range.start.line) {
        commands.push(command)
      }
    }
    if (!commands.length) return
    if (commands.length == 1) {
      await commandManager.execute(commands[0])
    } else {
      let res = await window.showMenuPicker(commands.map(c => c.title))
      if (res == -1) return
      await commandManager.execute(commands[res])
    }
  }

  private cancel(): void {
    this.resolveCodeLens.clear()
    this.fetchCodelenses.clear()
    if (this.tokenSource) {
      this.tokenSource.cancel()
      this.tokenSource.dispose()
      this.tokenSource = null
    }
  }

  public dispose(): void {
    this.clear()
    this.cancel()
    this.codeLenses = undefined
  }
}
