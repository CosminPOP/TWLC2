# TWLC2
Addon to help with Turtle Wow BWL Loot Council

When enabled, and the **Raid Leader** opens boss loot frame, the addon frame will pop up
allowing him to `broadcast` the loot to the raid.<BR>

Raiders will get item frames and options to pick for each item: BIS/MS/OS/pass<BR>

![loot frame](https://i.imgur.com/FS2NMC5.png)

After the picking time (configurable by the raid leader) has passed, officers will get a voting time
(configurable by the raid leader)<BR>

![voting time](https://imgur.com/oRrwY4E.png)

Hovering a player in the player list will show that player's loot history<Br>

![loot history](https://imgur.com/PZymm6u.png)

After the voting time has passed, the Raid Leader can distribute loot based on votes, if there are no vote ties.<BR>

In case there is a vote tie a `ROLL VOTE TIE` button will pop up and the addon will roll 1-100 for the people who are vote tied
and pick a winner based on the highest roll<BR><BR>

Loot can also be distributed if you click on a raider frame.<Br>

![distribute loot via raider list click](https://imgur.com/4ywEWTr.png)

<br>
Slashcommands:<br>
`/twlc add [name]` - Adds `name` to the loot council member list<br>
`/twlc rem [name]` - Removes `name` from the loot council member list<br>
`/twlc list` - Lists the loot council member list <Br>
`/twlc set ttn [sec]` - Sets the time available to raiders to `pick` BIS/MS/OS/pass when an item drops<br> 
`/twlc set ttv [sec]` - Sets the time available to loot council to `vote `
