# Navigation Utils
[![Pub release](https://img.shields.io/pub/v/navigation_utils.svg?style=flat-square)](https://pub.dev/packages/navigation_utils) [![GitHub Release Date](https://img.shields.io/github/release-date/searchy2/NavigationUtils.svg?style=flat-square)](https://github.com/searchy2/NavigationUtils) [![GitHub issues](https://img.shields.io/github/issues/searchy2/NavigationUtils.svg?style=flat-square)](https://github.com/searchy2/NavigationUtils/issues) [![GitHub top language](https://img.shields.io/github/languages/top/searchy2/NavigationUtils.svg?style=flat-square)](https://github.com/searchy2/NavigationUtils) [![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/searchy2/NavigationUtils.svg?style=flat-square)](https://github.com/searchy2/NavigationUtils) [![Libraries.io for GitHub](https://img.shields.io/librariesio/github/searchy2/NavigationUtils.svg?style=flat-square)](https://libraries.io/github/searchy2/NavigationUtils) [![License](https://img.shields.io/badge/License-BSD%200--Clause-orange.svg?style=flat-square)](https://opensource.org/licenses/0BSD)

> ### The missing navigation library for Flutter's Navigator 2. 

A collection of convenience methods and wrappers to help implement Flutter's Navigator 2 from the ground up. Use this library to get a head start and save hundreds of hours.

### Features

- Reimplements the Navigator 1 API in Navigator 2 [push(), pop(), etc].
- Absolute control over the navigation back stack [set()].
- Named route support [pushNamed(), setNamed()].
- Support for path based routing.
- Functions for setting the URL and query parameters.

### Should I use Navigation Utils?

Here's a handy diagram to help one decide whether or not to use Navigation Utils.

![Screenshots](packages/Use-Navigation-Utils-Decision-Diagram.png)

Navigation Utils is **NOT** more complex than other navigation libraries. However, instead of attempting to abstract away the complexity of Navigator 2, this library exposes the nuance and complexity of implementing navigation.

A few compelling arguments for using Navigation Utils: 

- You're learning how to use Flutter's Navigator 2, not a third party library. The time you invest won't be wasted.
- You'll be able to implement any navigation, no matter how complex.
- Create navigation that conforms to your app and  architecture instead of letting navigation drive architecture decisions.

As you implement more and more navigation features such as deeplinks, authentication, and URLs, you'll run into increasing roadblocks and limitations that increases cost. At a certain point, learning and working directly with Navigator 2 is imperative.

<p align="center">
<img src="packages/Navigation-Utils-Breakeven-Graph.png" width="600">
</p>

If you are running into navigation issues, bite the bullet and learn Navigator 2. There is an initial learning curve but the alternative is to run into countless issues, roadblocks, and limitations.

### Why is Navigator 2 so difficult?

