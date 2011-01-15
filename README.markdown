               [[http://img141.imageshack.us/img141/671/seionlogo.png | align=center]]

### What is SeiON?
SeiON is an Actionscript 3 Sound Library. Its goal is to provide a simplistic, fuss-free way to manage sound playback within Flash/Flex. By instantiating Sound objects through SeiON, you can have a layered approach to handling your sound playback. SeiON also incorporates an sound allocation system so that you don't have to keep track of every single sound instance, and will automatically dispose of them once they finish playback. By properly categorising sounds, SeiON will be able to recycle sounds and ensure that you'll always be able to keep playing more sounds without hitting the SoundChannel limit for the Flash Player.

In short, SeiON does the following:

* Provides a global sound manager for allocating sound instances in the Flash environment
* Allows for pause/resume playback for sounds.
* Provides an interface for playback of gapless MP3 loops in Flex.
* Keeps track of and auto-disposes finished/unwanted sound instances.
* Recycles sounds for continual creation of more sounds.

Visit the wiki for more details: https://github.com/cardin/SeiON/wiki/

--- THE ANIMATION LIBRARY
SeiON comes with GreenSock's Tweening Library, which can be used to chain animation events to SeiON internally. Usage of GreenSock is opt-in by initialising the engine at the start of the program.

GreenSock's Tweening Library comes under its own license, and is free for non-commercial usage. You can visit http://www.greensock.com/licensing/ to learn more about it.

------------------------------------------
Licensed under the MIT License

Copyright (C) 2011 by Cardin Lee

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

https://github.com/cardin/SeiON
http://www.opensource.org/licenses/mit-license.php