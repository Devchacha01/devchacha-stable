local Translations = {
    stable = {
        stable = "Stable",
        set_name = "Name your horse:",
        max_horses = "You can have a maximum of %s horses!",
        not_enough_money = "Not enough money!",
        horse_purchased = "Horse purchased successfully!",
        horse_sold = "Horse sold for $%s!",
        no_horse_selected = "No horse selected!",
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})