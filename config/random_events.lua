Config = Config or {}

Config.RandomDeliveryEvents = {
    Enabled = true,
    Chance = 0.28,
    Events = {
        {
            id = 'dock_delay',
            label = 'Dock Delay Issued',
            description = 'Dispatch issued a dock delay. Your route window was extended slightly.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 120,
            payoutPercent = 0.00,
            repBonus = 0
        },
        {
            id = 'rush_order',
            label = 'Rush Order Bonus',
            description = 'Dispatch marked this load urgent. Deliver clean and on time for a bonus.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = -60,
            payoutPercent = 0.07,
            repBonus = 1
        },
        {
            id = 'receiver_audit',
            label = 'Receiver Audit',
            description = 'The receiver is checking paperwork closely. Late arrivals are less forgiving.',
            types = { 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 0,
            payoutPercent = 0.04,
            latePenaltyBonusPercent = 0.05,
            repBonus = 1
        },
        {
            id = 'restricted_checkpoint',
            label = 'Restricted Route Checkpoint',
            description = 'Security requested careful handling through a checkpoint. Payout increased.',
            types = { 'trailer' },
            priorities = { 'government', 'military' },
            estimateDeltaSeconds = 180,
            payoutPercent = 0.10,
            repBonus = 2
        },
        {
            id = 'traffic_reroute',
            label = 'Traffic Reroute',
            description = 'A traffic reroute was issued. You have a little extra time, but no payout change.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 180,
            payoutPercent = 0.00,
            repBonus = 0
        },
        {
            id = 'bay_ready_early',
            label = 'Bay Ready Early',
            description = 'The receiver opened a dock early. Dispatch expects a cleaner arrival window.',
            types = { 'boxtruck', 'trailer' },
            estimateDeltaSeconds = -75,
            payoutPercent = 0.03,
            repBonus = 1
        },
        {
            id = 'scale_house_check',
            label = 'Scale House Check',
            description = 'A scale house check was added to the route. Time window extended.',
            types = { 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 150,
            payoutPercent = 0.05,
            repBonus = 1
        },
        {
            id = 'fragile_handling',
            label = 'Fragile Handling',
            description = 'Dispatch flagged fragile freight. Smooth driving earns a handling bonus.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 60,
            payoutPercent = 0.06,
            latePenaltyBonusPercent = 0.03,
            repBonus = 1
        },
        {
            id = 'priority_dock_lane',
            label = 'Priority Dock Lane',
            description = 'The receiver opened a priority dock lane. Deliver clean for a bonus.',
            types = { 'boxtruck', 'trailer' },
            priorities = { 'priority', 'government', 'military' },
            estimateDeltaSeconds = -90,
            payoutPercent = 0.04,
            repBonus = 1
        },
        {
            id = 'customer_call_ahead',
            label = 'Customer Call-Ahead',
            description = 'The customer confirmed staff on site. Dispatch tightened the ETA slightly.',
            types = { 'van', 'boxtruck' },
            estimateDeltaSeconds = -45,
            payoutPercent = 0.03,
            repBonus = 1
        },
        {
            id = 'construction_detour',
            label = 'Construction Detour',
            description = 'Construction crews blocked the planned approach. Extra route time approved.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 210,
            payoutPercent = 0.00,
            repBonus = 0
        },
        {
            id = 'freeway_closure',
            label = 'Freeway Closure',
            description = 'A freeway closure forced dispatch to reroute through surface streets.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 300,
            payoutPercent = 0.02,
            repBonus = 0
        },
        {
            id = 'security_seal_check',
            label = 'Security Seal Check',
            description = 'Security requested a seal check at delivery. Paperwork must match cleanly.',
            types = { 'trailer' },
            priorities = { 'government', 'military' },
            estimateDeltaSeconds = 180,
            payoutPercent = 0.08,
            latePenaltyBonusPercent = 0.04,
            repBonus = 2
        },
        {
            id = 'cold_chain_watch',
            label = 'Cold Chain Watch',
            description = 'Receiver requested temperature-safe handling. Keep the load moving.',
            types = { 'trailer' },
            estimateDeltaSeconds = 90,
            payoutPercent = 0.06,
            repBonus = 1
        },
        {
            id = 'warehouse_backlog',
            label = 'Warehouse Backlog',
            description = 'The warehouse is backed up. Dispatch added time and a small wait bonus.',
            types = { 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 240,
            payoutPercent = 0.03,
            repBonus = 1
        },
        {
            id = 'paperwork_addendum',
            label = 'Paperwork Addendum',
            description = 'Dispatch added a manifest note. Receiver paperwork will be checked closely.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 60,
            payoutPercent = 0.04,
            latePenaltyBonusPercent = 0.03,
            repBonus = 1
        },
        {
            id = 'clean_run_bonus',
            label = 'Clean Run Bonus',
            description = 'Dispatch posted a clean-run bonus. Avoid damage and arrive on schedule.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 0,
            payoutPercent = 0.05,
            repBonus = 1
        },
        {
            id = 'customer_escalation',
            label = 'Customer Escalation',
            description = 'The receiver escalated this order. Fast, clean delivery pays better.',
            types = { 'van', 'boxtruck', 'trailer' },
            priorities = { 'priority', 'government', 'military' },
            estimateDeltaSeconds = -90,
            payoutPercent = 0.08,
            latePenaltyBonusPercent = 0.06,
            repBonus = 2
        },
        {
            id = 'off_peak_window',
            label = 'Off-Peak Window',
            description = 'Dispatch found a lighter traffic window. Delivery window was tightened slightly.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = -120,
            payoutPercent = 0.03,
            repBonus = 1
        },
        {
            id = 'receiver_crew_break',
            label = 'Receiver Crew Break',
            description = 'Receiver crew is on break. Route window extended until the dock reopens.',
            types = { 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 180,
            payoutPercent = 0.00,
            repBonus = 0
        },
        {
            id = 'high_value_manifest',
            label = 'High Value Manifest',
            description = 'Dispatch tagged this as high-value freight. Careful handling pays extra.',
            types = { 'van', 'boxtruck', 'trailer' },
            priorities = { 'priority', 'government', 'military' },
            estimateDeltaSeconds = 60,
            payoutPercent = 0.12,
            latePenaltyBonusPercent = 0.05,
            repBonus = 2
        },
        {
            id = 'pallet_count_audit',
            label = 'Pallet Count Audit',
            description = 'Receiver will count every item at the dock. Dispatch added audit time.',
            types = { 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 120,
            payoutPercent = 0.05,
            latePenaltyBonusPercent = 0.04,
            repBonus = 1
        },
        {
            id = 'gate_code_update',
            label = 'Gate Code Update',
            description = 'The receiver changed the gate code. Dispatch added a short access delay.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 45,
            payoutPercent = 0.02,
            repBonus = 0
        },
        {
            id = 'weather_advisory',
            label = 'Weather Advisory',
            description = 'Dispatch issued a weather advisory. Time window extended for safer driving.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 150,
            payoutPercent = 0.04,
            repBonus = 1
        },
        {
            id = 'highway_patrol_notice',
            label = 'Highway Patrol Notice',
            description = 'Highway patrol activity reported ahead. Dispatch recommends a steady pace.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 90,
            payoutPercent = 0.02,
            repBonus = 0
        },
        {
            id = 'crane_hold',
            label = 'Crane Hold',
            description = 'Port crane traffic delayed yard access. Trailer window extended.',
            types = { 'trailer' },
            estimateDeltaSeconds = 240,
            payoutPercent = 0.05,
            repBonus = 1
        },
        {
            id = 'short_staffed_receiver',
            label = 'Short Staffed Receiver',
            description = 'Receiver is short staffed. Dispatch added time for unloading delays.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 120,
            payoutPercent = 0.03,
            repBonus = 0
        },
        {
            id = 'express_clearance',
            label = 'Express Clearance',
            description = 'Dispatch secured express clearance. Expected-by window tightened and payout increased.',
            types = { 'van', 'boxtruck', 'trailer' },
            priorities = { 'priority' },
            estimateDeltaSeconds = -90,
            payoutPercent = 0.05,
            repBonus = 1
        },
        {
            id = 'load_rebalance',
            label = 'Load Rebalance Request',
            description = 'Dispatch requested careful load balance at delivery. Extra handling pay added.',
            types = { 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 120,
            payoutPercent = 0.05,
            repBonus = 1
        },
        {
            id = 'remote_yard_checkin',
            label = 'Remote Yard Check-In',
            description = 'Receiving yard requires a radio check-in before drop. Extra time approved.',
            types = { 'trailer' },
            estimateDeltaSeconds = 90,
            payoutPercent = 0.04,
            repBonus = 1
        },
        {
            id = 'urban_delivery_window',
            label = 'Urban Delivery Window',
            description = 'City receiver opened a narrow ETA window. Clean arrival pays better.',
            types = { 'van', 'boxtruck' },
            priorities = { 'priority' },
            estimateDeltaSeconds = -60,
            payoutPercent = 0.06,
            latePenaltyBonusPercent = 0.04,
            repBonus = 1
        },
        {
            id = 'dispatch_favor',
            label = 'Dispatch Favor',
            description = 'Dispatch bumped your route up the board. Finish strong for a small bonus.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = -30,
            payoutPercent = 0.03,
            repBonus = 1
        }
    }
}
