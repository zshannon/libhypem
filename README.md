libhypem
===================================================
The definitive Cocoa framework for adding Hype Machine to your iOS/Mac app. This library includes fetching Playlists, fetching and favoriting Tracks, and User fetching and authentication.
---------------------

## Table of Contents

* [Installing](#getting-started)
* [Fetching Playlists](#fetching-playlists)
* [Fetching Tracks from a Playlist](#fetching-tracks)
* [Logging In/Out](#logging-inout)
* [Designing for the Future, and beyond!](#designing-for-the-future-and-beyond)
* [Apps that use libhypem](#apps-that-use-libhypem)
* [Tools that inspired libhypem](#tools-that-inspired-libhypem)
* [License](#license)

## Getting Started

Installing libhypem is a breeze. First things first, add all of the classes in the top-level **libhypem** folder inside of this repository into your app. Done? Good. Now, just `#import "libhypem.h"` in any of your controllers, classes, or views you plan on using libhypem in. That's it. We're done here.

Classes to add:
* libhypem.h
* APIClient.{h,m}
* Blog.{h,m}
* HypeM.{h,m}
* Playlist.{h,m}
* Track.{h,m}
* User.{h,m}

**CocoaPods**

If CocoaPods suits your flavor of dependency management, then there is a .podspec here for you as well. Just add the following line to your Podfile, and install your pods to get started with libhypem the easy way.

```ruby
pod 'libhypem'
```

---------------------

## Fetching Playlists

Pretty much everything on Hype Machine is a Playlist. `Playlist.h` has a method for each kind of playlist. Use it like this:

```objc
#import 'libhypem.h'

// Popular
Playlist *popularThreeDay = [Playlist popular:nil];
// Or a different time period
Playlist *playlistLastWeek = [Playlist popular:@"lastweek"];
// Or a specific genre
Playlist *playlistDance = [Playlist tagged:@"Dance"];
```

Once you have a `Playlist` instantiated, you can start paginating it, like this:

```objc
Playlist *playlist = [Playlist popular:nil];
[playlist getNextPage:^(NSError *error) {
	if (error == nil) {
		for (Track *track in playlist.tracks) {
			// Here are some `Track` objects. More on this later.
		}
	}
}];
```

Each time you call `getNextPage`, the `Playlist` will increment its page add tracks to its `tracks` property.

That's it for playlists.

---------------------

## Fetching Tracks

Once you've got a `Playlist`, you can start using its `Track`s. There are two methods for fetching download URLs: `publicDownloadURL` and `internalDownloadURL`. So HypeM's a little weird. Their native iOS app uses the same protocol as `publicDownloadURL`, but their website uses a different protocol, which is duplicated in `internalDownloadURL`. `publicDownloadURL` is far less brittle as it does not rely on scraping `hypem.com` for its data. YMMV.

```objc
Playlist *playlist = [Playlist popular:nil];
[playlist getNextPage:^(NSError *error) {
	if (error == nil) {
		for (Track *track in playlist.tracks) {
			// download the mp3 this way
			NSURL *downloadURL = [track publicDownloadURL]; 
			// or, another way
			[track internalDownloadURL:^(NSURL *url, NSError *error) {
				// use `url` here
			}];
			// if it's a great track, and you're logged in (more on that later), favorite it!
			[track toggleFavorite:^(NSError *error) {
				if (error == nil) {
					NSLog(@"%@ is a great track. One of my favorites!", track.title);
				}
			}];
		}
	}
}];
```

---------------------

## Logging In/Out

User related actions are a vital aspect of being part of the Hype Machine community. I mean, if you can't be active in favoriting tracks, then you might as well be a wall flower.

The way HypeM operates in the browser is off of an HTTP Cookie. This Cookie is generated on load, authenticated at login, and kept around for a pretty long time.

```objc
HypeM *h = [HypeM sharedInstance];
[h loginWithUsername:@"username" andPassword:@"password" andCompletion:^(User *user, NSError *error) {
	if (error != nil) {
		// Login worked. Now you can favorite the good `Tracks`
	}
}];
```

Logging out just deletes the Cookie property and the User property from memory, as well as the actual cookie from <code>[NSHTTPCookieStorage sharedStorage]</code>, so you can't use them any more to make user-specific requests like favoriting. Logging out is dead simple to implement.

```objc
[[HypeM sharedInstance] logout];
```

---------------------

## Designing for the Future, and beyond!

Well basically this is all hacked together because Hype Machine doesn't support a Public API. It'd be nice if they did.

---------------------

## Apps that use libhypem

Here's a list of iOS/Mac apps that use libhypem to provide sweet functionality. Use this library in your app? Open an issue and I'll add it to the list here:

---------------------

## Tools that inspired libhypem

* [Plug for Mac](http://www.plugformac.com/)
* [libHN](https://github.com/bennyguitar/libHN)
* [hypem](https://github.com/JackCA/hypem)

---------------------

## License

libhypem is licensed under the standard MIT License.

**Copyright (C) 2014 by Zane Shannon**

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

---------------------