# Single Media Player

Single Media Player is an iOS app that plays a single built-in video from
beginning to end repeatedly, has no visible elements aside from the playing
video, and refuses all user interaction.

It is a simple iOS app that solves a real problem and would have difficulty
existing in the AppStore. I use it to show a single pre-selected movie to a
toddler. When used along side [Guided Access](https://support.apple.com/en-us/HT202612),
no amount of accidental input will interrupt playback.

## Use

* Add a video file named `Media.m4v`
* Compile and run

I recommend enabling [Guided Access](https://support.apple.com/en-us/HT202612).
There is no need to disable any areas of the screen since the app won't do
anything in response to any input.

Or, you can replace `Media.m4v` with another piece of media in the Xcode project
and in the single place it's read in the source code.
