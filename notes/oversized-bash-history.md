# Oversized Bash history entries

**Status: Deferred.** Test the new duplicate and failed-command filters in daily use before changing how Bash saves long commands.

Long, one-off compound commands clutter history. They rarely match another entry, so deduplication does not remove them. The failed-command filter does not remove them when they succeed.

When revisiting this issue, review examples from actual history. Compare a length limit with a rule for long compound commands. Check which useful entries each rule would exclude before choosing one.
