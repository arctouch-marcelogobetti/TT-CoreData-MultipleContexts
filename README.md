# TT-CoreData-MultipleContexts
Tech talk about multiple contexts in Core Data @ ArcTouch

We start from Apple's original [DateSectionTitles](https://developer.apple.com/library/ios/samplecode/DateSectionTitles/Introduction/Intro.html#//apple_ref/doc/uid/DTS40009939)
example and as the complexity of the app grows, multiple `NSManagedObjectContext`s are
needed. And that surely brings a lot of caveats... Let's see some of the most common
ones and how to solve them.

All commits were intentional and they follow a development chronological order,
pretending to be the real evolution of a developer trying to fix bugs and finding
issues in the way. The commit messages explain what's going on.
