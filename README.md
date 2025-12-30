
# Roll your own Talos-based k8s cluster

The first question to ask is "Why bother?". There are many reasons.

## Customer demand
In recent history, demands of customers shifted. While, in the past, being "in the cloud" was a positive,
it is starting to be a hurdle for sales if they have to admit that your SaaS is hosted on one of the hyperscalers.

Whether it is rational or not is not of concern. SMEs have an emotional reaction to US-based tech these days and would rather
be hosted somewhere in the EU.

## Portability
Developing against k8s as your infrastructure gives you optionality. You could continue hosting it on Hetzner and a few bare metal servers or VMs
or you can move it to a managed cluster on Scaleway, Exascale, or move to a Hyperscaler after all. Most of your deployments are describes as k8s
resources and you therefore won't have to rework them.

## Cost
Hyperscalers are expensive. Heralded as a cost-saving measure in the past we now know that their margins are VERY good - hence you're likely paying a lot.


# Installation
This repository manages all tools necessary via mise (https://mise.jdx.dev/getting-started.html).

``` sh
mise install
```
