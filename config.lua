return {
    -- FiveM control IDs: E = 38, X = 73.
    consumeControl = 38,
    stopControl = 73,

    items = {
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
                -- 0.2 means 20% of the item's durability per consume.
                consumePercent = 0.2,
                useLabel = 'Drink slowly'
            }
        },

        -- Example for another item:
        -- water_bottle = {
        --     status = {
        --         thirst = 200000
        --     },
        --     normal = {
        --         anim = {
        --             dict = 'mp_player_intdrink',
        --             clip = 'loop_bottle',
        --             flag = 49
        --         },
        --         prop = {
        --             model = 'prop_ld_flow_bottle',
        --             bone = 28422,
        --             pos = vec3(0.12, 0.008, 0.03),
        --             rot = vec3(240.0, -60.0, 0.0)
        --         },
        --         duration = 2500,
        --         label = 'Drinking water'
        --     },
        --     slow = {
        --         prop = {
        --             model = 'prop_ld_flow_bottle',
        --             bone = 28422,
        --             pos = vec3(0.12, 0.008, 0.03),
        --             rot = vec3(240.0, -60.0, 0.0)
        --         },
        --         idle = {
        --             dict = 'amb@world_human_drinking@beer@male@idle_a',
        --             clip = 'idle_a',
        --             flag = 49
        --         },
        --         consume = {
        --             dict = 'amb@world_human_drinking@coffee@male@idle_a',
        --             clip = 'idle_a',
        --             flag = 49,
        --             duration = 5500,
        --             notification = 'You take a drink of water'
        --         },
        --         consumePercent = 0.2,
        --         useLabel = 'Drink slowly'
        --     }
        -- }
    }
}