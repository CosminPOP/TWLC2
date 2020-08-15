# TWLC2 v1.1.0.2
_!!! Remove `-master` when extracting into your `interface/addons` folder !!!_<BR><BR>
Addon to help with Turtle Wow BWL Loot Council<BR><BR>

<hr>

**v1.1.0.2**<br>
<br>
Fixes not being able to vote if not everyone in raid had the TWLC2c addon 

<hr>

**v1.1.0.1 - Horde Sattelite**<br>
<br>
Added option to set a horde sattelite player that can ML and broadcast horde loot<br>
Use `/twlc set sattelite [name]` to set it<br>
Added icons with name tooltips for which CL voted<br>
Added attendance data, disable for now. 
<hr>

**v1.1.0.0 - First Major Update**<br>
<br>
Changed comm channel to `TWLC2`<br>
Items for LC get sent via `preloadInVoteFrame=` in Prepare Broadcast (first step of Broadcast Loot)
<hr>

**v1.0.2.3**<br>
`/twlc autoassist` - Toggle autoassit for CL/Officers on or off<Br>
Infinite loop fix for autoassist
<hr>

**v1.0.2.2**<br>
`/twlc scale [0.5-2]` - Sets main frame scale from 0.5x to 2x<Br>
`/twlc alpha [0.2-1]` - Sets main frame opacity from 0.5 to 1<br>
* **Done Voting** button for when you're done voting current item, or just don't wanna vote for current item<Br>
* Ability to resize the main window from 5 to 15 visible players<br> 
<hr>


When enabled (from the minimap button, disabled by default), and the **Raid Leader** opens boss loot frame, the addon frame will pop up
allowing him to `broadcast` the loot to the raid.<BR>
![broadcast button](https://imgur.com/kxV59t1.png)

Raiders will get item frames and options to pick for each item: BIS/MS/OS/pass<BR>
***Note:** Raiders require https://github.com/CosminPOP/TWLC2c addon for pick frames*<Br>
![loot frame](https://i.imgur.com/FS2NMC5.png)

After the picking time (number of items * 30s) has passed, officers will get a voting time
(number of items * 60s). Officers will also see the current raider's items.<BR>

![voting time](https://imgur.com/oRrwY4E.png)

Clicking a player in the player list will show that player's loot history<Br>

![loot history](https://imgur.com/PZymm6u.png)

After the voting time has passed, the Raid Leader can distribute loot based on votes, if there are no vote ties.<BR>

Loot can also be distributed if you right-click on a raider frame.<Br>

![distribute loot via raider list click](https://imgur.com/4ywEWTr.png)

In case there is a vote tie a `ROLL VOTE TIE` button will pop up. Pressing it will ask tie raiders to roll.<BR>

![rollframe](https://imgur.com/cqaJlbf.png)

Rolls are recorded and shown to officers. ML can distribute the item based on the roll winner<Br>

![rollwinner](https://imgur.com/886zw8y.png)

Slashcommands[RL]:<br>
`/twlc add [name]` - Adds `name` to the loot council member list<br>
`/twlc rem [name]` - Removes `name` from the loot council member list<br>
`/twlc list` - Lists the loot council member list <Br>
`/twlc who` - Lists people with the addon <Br>
`/twlc set ttnfactor [sec]` - Sets the time available to players to pick for each item (final duration is number of items * this factor, in seconds)<Br>
`/twlc set ttvfactor [sec]` - Sets the time available to council members to vote for each item (final duration is number of items * this factor, in seconds)<Br>
`/twlc set ttr [sec]` - Sets the time available to players to roll in a vote tie case<Br>
`/twlc synchistory` - Syncs loot history with other people with the addon.<Br>
`/twlc debug` - Toggle debugging on or off<Br>
<Br>



Known bugs:
* Icons of Items you haven't seen don't show up in the `replaces` fields or show up as `?` icon.
