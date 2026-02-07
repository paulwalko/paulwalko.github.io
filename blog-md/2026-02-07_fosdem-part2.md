# Air Quality Monitoring at FOSDEM 2026: Part 2
See https://paul.walko.org/blog/2026_01_25-meshtastic-fosdem-part1.html for background about this effort. This idea was initially thought of by Crofton, but it wasn't until we came across Meshtastic as a good method of transporting metrics that this became a reality.

## Day 1 CO2 Metrics
<img width="955" height="284" alt="Day 1 CO2 Metrics" src="https://github.com/user-attachments/assets/93bdb9e3-6b31-4d5b-90a8-67ebb05a2620" />

Here's the detailed readings for each node:
- CRA devroom at 5000 ppm
- "Building Europe’s Public Digital Infrastructure", initially at 4000 ppm but went down to 2000.
- Grafana stand (K building), around 1800 ppm all day
- Networking devroom, around 1500 ppm all day
- Robotics devroom, starting at 4000 ppm then declined to 2000 ppm in the afternoon.
- Virtualization devroom, at 2000 ppm
- Gnuradio stand (AW building), around 2000 ppm all day

At first glance here, the CRA devroom makes everything else look insignificant. This is partially true, but excluding that shows that most other rooms were above 2000 ppm nearly the whole day
<img width="955" height="284" alt="Day 1 CO2 Metrics excluding CRA devroom" src="https://github.com/user-attachments/assets/c5708e9c-bf86-4eb6-adb8-0290712e9b7d" />

This isn't particuarly surprising given just how many people attend FOSDEM each year, and hopefully it will encourage devroom managers to think about air circulation in future years. A very rough guideline is to start opening windows or doors when the ppm gets above 2000. I believe the CRA devroom windows weren't easily openable, plus the hallway was rather noisy so opening the doors wasn't practical.

### Day 1 Temperature & Humidity
The scd41 sensors measures temperature & humidity in addition to CO2:
<img width="955" height="816" alt="Day 1 CO2, Temperature, and Humidity Metrics" src="https://github.com/user-attachments/assets/3b3450af-a858-4b08-9545-06dffb0a7f35" />

You can see a rough correlation between temperature and CO2. I believe the sensor at the Grafana stand was placed on top of a 3d printer, hence the high temps. The CRA sensor may have also been placed on top of a radiator (?), which affects the sensor in weird ways.

## Day 2 CO2 Metrics
By this point I was tired of organizing distribution of nodes so we had much less rooms to monitor that Day 1, but there are still some interesting results:
<img width="955" height="276" alt="Day 2 CO2 Metrics" src="https://github.com/user-attachments/assets/60a332ab-a312-4aab-97dd-e4a4f42aa4ab" />

### Day 2 Temperature & Humidity
<img width="955" height="825" alt="Day 2 CO2, Temperature, and Humidity Metrics" src="https://github.com/user-attachments/assets/c863e245-7529-4163-af7a-f7420f4f78da" />


The SDR devroom topped out at about 3000 ppm in the morning, but unfortunately the sensor was not present in the room for the afternoon. The room reportedly got more packed as the day went on, so this likely went at least to 4000 ppm if not higher.

## Summary & Improvements
By far, the biggest hurdle was distribution of the monitoring nodes. FOSDEM staff did not allow us to place nodes without someone (such as devroom managers) watching over them at all times, otherwise we would've liked to place them Friday evening before the conference started. Once sessions got going, placing nodes proved to be very difficult to get into rooms.

I am hoping that by next year there is a low cost commercial alternative that FOSDEM staff can trust, since a large part of them being against this year's nodes was that it was DIY and they have no knowledge of how hacked together the nodes were. (Note that we only had 1 out of 20 nodes stop working for some random reason).
