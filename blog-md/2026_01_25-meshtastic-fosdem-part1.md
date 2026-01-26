# Air Quality Monitoring at FOSDEM 2026: Part 1
### Background
A few years ago at the 2022 NSS Convention, COVID was a big deal, and a large portion of attendees got covid as a result. Philip Balister (@Balister) conveniently had his Aranet co2 sensor which he brought around to some sessions to gauge how bad ventilation is, and more often than not people were not aware of just how badly co2 readings can be in rooms that are filled with people.

Fast-forward to 2025, we discovered Meshtastic (https://meshtastic.org) and had the idea to place a meshtastic node in each session room, then remotely monitor and visualize measurements. There are several already existing sensors such as the Aranet, but nearly all require ble or wi-fi. Meshtastic allows us to not be reliant on already existing networking infrasturcture and has qutie a large range.

## Test Run: NSS Convention 2025
I belive we got started with Meshtastic in Fall 2024, primarily as a potential cave rescue comms system, but this quickly evolved into the CO2 monitoring project.

Here's the main repo for the node we made: https://github.com/paulwalko/faketec-co2. This is heavily based on gargomoma's faketec v2 board, but instead of a screen we use a SCD41 CO2 sensor. It just so happened that the screen pins and SCD41 pins lined up exactly how we needed them to, resulting in zero PCB modification:
<img width="685" height="405" alt="CO2 monitoring node" src="https://github.com/user-attachments/assets/a2db2521-bbf2-4570-8763-aed0e4f19c5c" />

At the time Meshtastic did not have support for the SCD41 sensor, so I was curious if I could simply stack a second board to gather measurements and send them back to Meshtastic. To my surprise this worked flawlessly, with the bottom board in the image running Circuit Python and the top board running Meshtastic. Both boards are NRF52 based, meaning their serial TX/RX pins can be dynamically changed. The circuitpy functioned as the "main" board, turning on and off the Meshtastic board every so often and sending measurements over serial.

With the hardware figured out, there are still quite a few additional pieces: battery, cables, on/off, and an enclosure. All of these are fairly simple by themselves, but combining all of them plus having to assemble 20 functional nodes quickly proved to be extremely time consuming.

Here's the finished node:

<img width="807" height="545" alt="Node interior" src="https://github.com/user-attachments/assets/1cbb9ef2-d73f-4e63-92ac-a2a36de456fd" />


And the bottom, exposing the SCD41 CO2 sensor:

<img width="502" height="454" alt="Node bottom" src="https://github.com/user-attachments/assets/a159878a-4149-4186-a2d8-d8018320ce28" />



Finally, at the 2025 NSS Convention we successfully deployed these, with a single gateway node to push data to MQTT. Unfortunately the data was lost to my the datacenter where my server was hosted getting evicted, but we will soon have more data with FOSDEM!

## FOSDEM 2026 Preparation
Since the NSS Convention, Meshtastic has much better support for the SCD41 sensor. Though not yet merged, I have been running the feature branch on all 20 of my nodes with no issue. The hardest part here was ensuring all the nodes had their circuitpy boards disabled, plus ensuring all the configuration in Meshtastic is correct. For reasons I can't explain, nodes seem to randomly pick some settings to apply and some to not. In any case, all the nodes are functional and viewable at https://mesh.caving.dev/public-dashboards/e2105032b16d47b9a42ee319d17e72b4.

A preview of what's to come:
<img width="942" height="314" alt="CO2 Dashboard" src="https://github.com/user-attachments/assets/c8aebb1c-0ce9-4d8b-9c91-c6cca111881e" />

