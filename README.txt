heka
====

To say it with an analogy, heka is to OsiriX/Horos what Thorium is to Chrome.

OsiriX is the masterpiece of Antoine Rosset for medical imaging viewing.  Went from almost opensource to closed one. Remained almost unchanged then, or at least without transcendant upgrades for years.  The licensing by subscriptions imposed now is a pain in the ass.

Horos was able to maintain the almost opensource code and make it truely opensource. This implied to get rid of three executables: aycan print, kakadu jpeg 2000, and pap3 (papyrus 3), el parser de Antoine. kakadu can be replaced by openjpeg or by grok (which is an improvement of openjpeg). And papyrus was one of the two engines included into Osirix. Horos kept the second one only.

In the last open source code published by Horos, there still is a lot of apple-playground distraction that where found in OsiriX code. We decided to cleaned up all this. After doing so, we well improve the product at its core with transcendant upgrade:
- DCKV parser/store designed to work with huge studies and IA (instead of papyrus)
- j2kht
- Weasis 4
- encapsulatedCDA
- ...



