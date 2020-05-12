# Heartbeat
> An experimental library for love2d to quickly create games without the boilerplate.

## Features
* A collision framework
* A ready-to-use camera
* A simple entity/tile creator/manager
* A level reader/writer
* A level editor
* A player inventory manager
* A dialog framework (coming soon)
* A simple menu system (coming soon)

## Installation
Simply copy the contents of `lib/` to the `lib/` folder of your project. `main.lua` is a sample of how to use Heartbeat and the possible applications it has.

## Usage
For now, refer to `main.lua` on how to create valid entity/tile objects and use them with Heartbeat. The project is a work in progress, but expect official docs soon.

## FAQ
**What version of lua/love2d should I be using?**
At the time of this writing, Heartbeat currently targets lua 5.3 and love2d 11.1. As either of these get updated, Heartbeat will be as well.

**Can I use this in my game?**

Of course. Heartbeat is licensed under MIT, meaning you can do whatever you want with it, even package it with games to sell.

**Could you add X to Heartbeat?**

Create a new issue and give it the `Enhancement` label and I'll see what I can do.

**Is Heartbeat in a usable state?**

Short answer: Yes. Long Answer: It depends on what you define as usable. As of right now, the project is a work in progress, so expect frequent and possibly breaking changes until 1.0.

**Will there be a luarocks package?**

I'm fully open to it. However, I personally don't use luarocks myself, so I have no idea the logistics behind submitting it and getting it approved. When I last used luarocks, I encountered numerous issues with it, so even if a rock _did_ exist someday, I'd still recommend copying the `lib/` files directly to your project.

