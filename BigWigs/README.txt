This is a work in progress and as such think will not always be correct and will quite possibly break.
The list below details where progress is and what works/does not work.
# Tier 4:

Karazhan 	- No plans to Update

Magtheridon	- ■■■■■■■■■□ 90%
- Missing proper Blast Wave timer after Cave in

HKM 		- No plans to update
Gruul 		- ■■■■■■■■■□ 90%
- Need proper timers on silence

# Tier 5:
-----------------------SSC--------------------------
Lurker		- ■■■■■■■■□□□ 70%
- Second dive broke
- Need whirl bar if it skips
- Issue is that there is not combat log event for spout or whirl, other then player getting hit
FLK
- Spitfire timer?
Leotheris   - ■■■■■■■■■■ 99%
- Missing first WW timer after split
Morogrim  	- ■■■■■■■■■□ 90%
- Needs testing on Grobule Timers
Hydross   	- ■■■■■■■■■□ 90%
- Looks good
- Verify Mark timers
- Write my own/cut out the spam
Vashj	  	- ■■□□□□□□□□ 20%
- Fixed issues where charge alert would break and correctly registered monster_yell event
- Should work


-------------------------The Eye-------------------------
Al'ar		- □□□□□□□□□□ 00%
- No timers first phase (Platform/Quills transistion)(NO idea before first quills but after, seems to be 30 sec)
- No melt armor timer (60sec)
- Check rest of timers (Dive bomb,flame patch)
- Possible to detect quills?	
Void Reaver	- ■■■■■■■■■■ 95%
- Maybe add icon to orb target
Solarian	- □□□□□□□□□□ 00%
- Needs work
- Check timers for
	1) Wrath of the Astromancer (Bomb debuff)
	2) Disapear/Reapear (wiki@ 50sec/15sec)
- Use lurker scan code to check for emerge
Kael'thas	- ■■■■■□□□□□ 50%
- need gaze cd (avg is 9 sec, will do 8.5 avg-stdev)
- pyro timer after first is bad
- cancel pheonix timers on transition
- first Gravity lapse early

# Tier 6
-----------Hyjal--------------
Rage		- ■■■■■■■■■□ 90%
- Minor improvment to timers
Anetheron	- ■■■■■□□□□□ 50%
- Timers look good
- Need my own code
- Add skull to infernal target
Kazrogal	- ■■■■■□□□□□ 50%
- Need my own code
- Need all timers
	1) Mark (Code looks good)
	2) Stomp 10?
	3? Cleave
Azgalor		- ■■■■■■■■□□ 80%
- Timers could be improved, but after doom target stuff is fixed its good to go
- Howl timer could be improved
- Fix doom target alert
Archimonde	- ■■■■■■■■□□ 80%
- Current code works great
- Add burst code/proximity

-----------------Black Temple-------------------
Najentus	- ■■■■■■■■■□ 90%
Supremus	- ■■■■■■■■■□ 90%
Akama		- □□□□□□□□□□ 00% -No timers in original code
Teron		- ■■■■■■■■■□ 90%
R.o.S.      - □□□□□□□□□□ 00% -
Gurtogg		- ■■■■■■■□□□ 70% - Group Numbering Wrong
Mother		- ■■■■■■■■■□ 90%
Council		- ■■■■■■□□□□ 60% - Could use a lot less clutter
Illidan		- ■■■■■■□□□□ 60% - Double check timers

# Zulaman
-In general needs testing

Akilzon		- □□□□□□□□□□ 00% 
Halazzi		- □□□□□□□□□□ 00%
Janalai		- □□□□□□□□□□ 00%
Nalorakk	- □□□□□□□□□□ 00%
Malacrass	- □□□□□□□□□□ 00%
Zuljin		- □□□□□□□□□□ 00% -Missing first timer on Paralize

# Tier 6.5

Kalecgos	- ■■■■■■■■■□ 90%
Brutallus	- ■■■■■■■■■■ 100% 
Felmyst		- ■■■■■■■■■□ 90% - Sometimes misses the first gas nova after landing
Twins		- ■■■■■■■■■■ 100%
Muru		- ■■■■■■■■■□ 90% - Could use "better" p2 times
Kiljaeden	- ■■■■■■■■■□ 90% - Missing the "useless" 15minute enrage timer
