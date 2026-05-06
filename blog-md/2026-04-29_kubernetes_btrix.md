# IPv6 only Kubernetes on tailscale and finally a reasonable self-hosted photos solution

A few years ago I discovered https://github.com/webrecorder/browsertrix, a full featured web archiving tool. I've made much simpler attempts at this before such as using their cli or wget, but this seemed like a good excuse to run Kubernetes since they only support helm charts, at least for official self-hosting.

## Slow Residential connection problems
I was able to spin up k8s on my homelab/backup server, the biggest problem here was that it's nearly impossible to share with anyone else due to the server being hosted at home. This is made worse when I archived rather large websites of 25GB+.  

I'd mostly forgotten about this project until recently, when I remembered I had a spare thinkpad mini pc with 64GB (!!) of memory. Another issue was the primary homelab server is rather old and memory constrained with 16GB, so it quickly falls over when crawling several pages or when serving them up to be viewed. Anyways, the mini pc made a great addon and (much with the help of claude) I had a fully functional multi-node cluster going. Somewhere along this time I decided it should be IPv6 only because why not, which proved to be rather educational getting all of that working. In particular I discovered just how powerful k8s patching can be.  

Still, both the primary and worker nodes are restricted by my slow residential ISP, so naturally the next step was to migrate my primary Hetzner server to run k8s. Previously it was a collection of docker scripts that works pretty well, and most of all is super simple, but well k8s is more fun. I'm sure I'll switch to something else entirely within a year.  

## AI
Yes, I did heavily use claude to debug and get things working initially. I work with docker and containers on a daily basis and have a good idea of how things *should* work, but was not super familiar with the internals of Kubernetes and really didn't want to spend months figuring it out. That being said, there's quite a few interesting networking obstacles specifically related to IPv6-only and Tailscale I had to overcome:

- Probably the most obvious; many applications don't have IPv6 enabled by default. I found that more often than not, the underlying libraries do so this was a matter of applying patches or overriding env vars, or even applying a patch to a bundled `node_modules` library.
- Accepting IPv4 + IPv6: Accepting IPv6 is trivial since the cluster already supports it, but also having IPv4 required having traefik listen on the host + socat for a few services that I don't want to or can't proxy.
- Firewalling: Initially I wanted to keep everything on the host, but because of how k8s ports bind directly in the kernel this was rather difficult. Coupled with NAT64 made this pretty much impossible so I eventually used Hetzner's built-in firewall support (which seems to be how k8s is designed; have someone else manage firewall).
- Not so much a huge hurdle, but tailscale's route advertising feature is very useful and easy to use.

## Nextcloud, RustFS, QField
These services are all rather new additions to my self-hosted stack.

- Nextcloud is well known as being the "standard" google drive alternative, but is also well known for being bloated. I'm happy to say I got this running and it feels just about as slow or less slow as onedrive or google drive.
- RustFS is a *very* new self-hosted S3 provider. It's really taken off now that minio has archived their open source repo and is a more or less a direct drop-in replacement. I'm sure I'll be the first to know when they release a bug as they only had a beta release last week.
- QField is another service I'd been wanting to host for a while now, but the provided self-hosted setup just wasn't very user friendly and Mergin Maps solves the same problem. Another case where I had claude sort through the confusing docs and get things working.

# Self-hosted Photos
For nearly 8 years now I've been self-hosting photos after getting frustrated with Google Photos.  

I think in that time I've tried Photosync (native SMB) + some viewer, nextcloud, syncthing, and more recently Immich.  

In any case, I have a few requirements:
- Web & mobile interface to browse and search
- Automatic backup from Android
- Lagless video playback
- Photos should be stored on disk and accessible in a simple file structure

Taking all that into account:

```
Android (running photosync) -- sync --> SMB endpoint; saves at /archive/photos <-- Immich reads and indexes as external library
                                                                       ^
                                                                       |
                                                                       |
                                    syncthing reads and syncs to devices for lagless video playback
```

I was running plain Immich for a few years, but the biggest issue was video playback is always laggy, whether it's in the web browser or mobile app.
