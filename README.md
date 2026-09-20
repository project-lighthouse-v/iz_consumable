# iz_consumable

This script adds a simple but flexible way to define items that can be consumed in two modes:
- Normal use: a quick progress bar consumption action
- Slow use: a held/drinking loop that drains durability over time and restores status such as thirst or hunger

It is designed for servers using ox_inventory and qbx_smallresources while keeping item data persistent through durability metadata.

## Features

- Supports durable inventory items with metadata-based depletion
- Restores QBox hunger/thirst using configured status values
- Supports both quick and slow consumption animations and props
- Automatically removes empty items from inventory
- Lets you configure custom item definitions in a single config file
- Handles client-side hold/consume states and controls cleanly

## Requirements

This resource depends on:

- ox_lib
- ox_inventory
- qbx_core
- qbx_smallresources

## Installation

1. Place the folder in your server resources directory, for example:

   resources/iz_consumable

2. Ensure the dependencies are installed and started before this resource.

3. Add this to your server.cfg:

   ensure iz_consumable

## Project structure

- config.lua — item definitions and consumption settings
- client.lua — client-side interactions, animations, UI, props, and controls
- server.lua — inventory checks, durability handling, status restoration, and consumption logic
- fxmanifest.lua — resource metadata and dependencies

## How it works

When a configured item is used, the script checks whether it has a slow consumption action.

If it does, the player enters a holding state and sees a UI prompt:

- E: Drink slowly / consume action
- X: Put away

The script then loops through the configured slow-consume animation and updates item durability with each cycle. When durability reaches zero, the item is removed from inventory.

Normal consumption still works for items that define a quick `normal` action.

## Configuration

The main configuration is in `config.lua`.

Example item definition:

```lua
bean_coffee = {
    status = {
        thirst = 200000
    },
    normal = {
        anim = {
            dict = 'mp_player_intdrink',
            clip = 'loop_bottle',
            flag = 49
        },
        prop = {
            model = 'prop_fib_coffee',
            bone = 60309,
            pos = vec3(0.03, 0.00, 0.02),
            rot = vec3(0.0, 0.0, -1.5)
        },
        duration = 2500,
        label = 'Drinking coffee',
        notification = 'You drank the coffee'
    },
    slow = {
        prop = {
            model = 'prop_fib_coffee',
            bone = 28422,
            pos = vec3(0.01, 0.01, 0.02),
            rot = vec3(5.0, 5.0, -180.5)
        },
        idle = {
            dict = 'amb@world_human_drinking@coffee@male@base',
            clip = 'base',
            flag = 49
        },
        consume = {
            dict = 'amb@world_human_drinking@coffee@male@idle_a',
            clip = 'idle_a',
            flag = 49,
            duration = 5500,
            notification = 'You take a sip of coffee'
        },
        consumePercent = 0.2,
        useLabel = 'Drink slowly'
    }
}
```

### Config values

- `status`: QBox status values restored when consumed
- `normal`: quick action config
- `slow`: repeated consume config for held use
- `consumePercent`: percentage of durability removed per consume step
- `duration`: animation/progress length
- `prop`: object attached to the player during animation
- `notification`: text shown after action completes

## Durability behavior

Durability is read from an item metadata field called `durability`.

- If durability is a number, it is consumed as the item is used
- If it reaches zero, the item is removed from the inventory automatically
- The script supports durability values over 100 and degrades them using the `degrade` metadata property when present

## Notes

This resource is built around using item metadata as a persistent state, which makes it ideal for inventory systems where consumables should not be effectively infinite.

You can expand the config by adding more custom items, animation sets, and status effects while keeping the same resource logic.

## License

This project is distributed as-is for use in FiveM roleplay servers. If you are publishing modified forks, keep the original credit and respect the third-party dependencies used by this script.

