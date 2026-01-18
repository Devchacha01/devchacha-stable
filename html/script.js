$('#creatormenu').fadeOut(0);

// Menu Navigation Handler
$(document).on('click', '.menu-selectb', function () {
    if ($(this).hasClass('disabled')) return;

    var target = $(this).data('target');

    $('.menu-selectb').removeClass('active');
    $(this).addClass('active');

    $('#page_myhorses, #page_shop, #page_customization').hide();
    $('#' + target).show();
});

var hasCustomized = false;
var initialComponents = {};
var currentComponents = {};

function getItemPrice(val) {
    if (val <= 0) return 0;
    // Determinstic price based on ID: Range $5 - $10
    return 5 + (val % 6);
}


var currentLocation = "Valentine"; // Default

window.addEventListener('message', function (event) {
    if (event.data.action == "show") {
        currentLocation = event.data.location || "Valentine";
        hasCustomized = false;
        initialComponents = {};
        currentComponents = {};

        // Capture initial state from DOM inputs after a short delay to ensure they are set
        setTimeout(function () {
            $('.input-number').each(function () {
                var cat = $(this).attr('id');
                var val = parseInt($(this).val()) || 0;
                initialComponents[cat] = val;
                currentComponents[cat] = val;

                // Initialize UI prices
                var $btn = $(this).siblings('.button-right'); // Just grab a sibling to find context
                if ($btn.length) {
                    var max = parseInt($(this).attr('max')) || 100;
                    updateCustomizationUI($btn, val, max);
                }
            });
        }, 100);

        $("#creatormenu").fadeIn(500);


        if (event.data.shopData) {
            for (const [index, table] of Object.entries(event.data.shopData)) {
                var horseCategory = table.name

                if ($(`#page_shop .scroll-container .collapsible #${index}`).length <= 0) {
                    $('#page_shop .scroll-container .collapsible').append(`
                         <li id="${index}">
                            <div class="collapsible-header col s12 panel ">
                                <div class="col s12 panel-title">
                                    <h6 class="grey-text">${horseCategory}</h6>
                                </div>
                            </div>
                            <div class="collapsible-body item-bg">
                            </div>
                        </li>
                    `);
                }

                for (const [_, horseData] of Object.entries(table)) {
                    if (_ != 'name') {
                        let Modelhorse
                        var HorseName = horseData[0];
                        var priceGold = horseData[1];
                        var priceDolar = horseData[2];
                        var BuyModel = null;

                        // priceGold = '';
                        // priceDolar = '';


                        $(`#page_shop .scroll-container .collapsible #${index} .collapsible-body`).append(`

                            <div id="${_}" onmouseenter="loadHorse(this)" class="col s12 panel item" style="display: flex; align-items: center; justify-content: space-between; padding: 10px;">

                                <div class="col s5">
                                    <h6 class="grey-text title" style="color:white; margin: 0; font-size: 0.9rem;">${HorseName}</h6>
                                </div>          

                                <div class="col s7" style="display: flex; align-items: center; justify-content: flex-end; gap: 10px;">
                                    <div class="gender-select" data-model="${_}" style="display: flex; gap: 6px;">
                                        <button class="btn gender-btn male-btn active" data-gender="Male" style="padding: 5px 15px; background: #2196F3; color: white; font-weight: bold; font-size: 1.5rem; min-width: 45px; height: 36px; line-height: 1; border-radius: 4px;">
                                            ♂
                                        </button>
                                        <button class="btn gender-btn female-btn" data-gender="Female" style="padding: 5px 15px; background: #555; color: white; font-weight: bold; font-size: 1.5rem; min-width: 45px; height: 36px; line-height: 1; border-radius: 4px;">
                                            ♀
                                        </button>
                                    </div>
                                    <button class="btn-small buy-btn" onclick="buyHorseWithGender('${_}', ${priceDolar})" style="display: flex; align-items: center; gap: 4px; background: #4CAF50;">
                                        <img src="img/money.png" style="height: 16px;"><span class="horse-price">${priceDolar}</span>
                                    </button>
                                </div>
                                
                            </div>
                        `);

                        $(`#page_shop .scroll-container .collapsible #${index} .collapsible-body #${_}`).on('click', function () {
                            $('.selected').removeClass("selected");
                            Modelhorse = $(this).attr('id');
                            $(this).addClass("selected");
                            $.post('https://devchacha-stable/loadHorse', JSON.stringify({ horseModel: $(this).attr('id') }));
                        });


                    }
                }

            }


            $('#page_myhorses .scroll-container .collapsible').html('');
            $('#page_myhorses .scroll-container .collapsible').append(`
                <li>
                    <div class="collapsible-header col s12 panel ">
                        <div class="col s12 panel-title">
                            <h6 class="grey-text">You don\'t have any horses!</h6>
                        </div>
                    </div>
                </li>
            `);
            $('#page_shop .collapsible, #page_myhorses .collapsible').collapsible();
        }
    }

    // Handle hide action - MUST be outside the "show" block!
    if (event.data.action == "hide") {
        $("#creatormenu").fadeOut(500);
    }


    if (event.data.EnableCustom == "true") {
        $('#button-customization').removeClass("disabled");
    } else {
        $('#button-customization').addClass("disabled");
    }


    if (event.data.myHorsesData) {

        $('#page_myhorses .scroll-container .collapsible').html('');

        for (const [ind, tab] of Object.entries(event.data.myHorsesData)) {

            let HorseName = tab.name;
            let HorseID = tab.id;
            let HorseIdModel = tab.model;
            let componentsh = tab.components;
            let selectedh = tab.selected;

            // Stats
            let gender = tab.gender || 'Male';
            let age = tab.age || 0;
            let xp = tab.xp || 0;
            let iq = tab.iq || 0;
            let genderSymbol = gender == 'Female' ? '♀' : '♂';
            let genderColor = gender == 'Female' ? '#E91E63' : '#2196F3';

            // Ensure stable property exists or default it
            let stableLoc = (tab.stable && tab.stable != "null") ? tab.stable : "Valentine";
            let uniqueHeaderID = `header-${HorseID}`;

            $('#page_myhorses .scroll-container .collapsible').append(`
                <li>
                    <div id="${uniqueHeaderID}" class="collapsible-header col s12 panel" style="background-color: transparent; border: 0; min-height: 80px; display: block; padding: 10px;">
                        
                        <div class="row" style="margin: 0; margin-bottom: 5px;">
                            <div class="col s12 center-align">
                                <h6 class="grey-text" style="font-size: 1.5rem; margin: 0; color: #e0e0e0;">${HorseName}</h6>
                            </div>
                        </div>

                        <div class="row" style="margin: 0; margin-bottom: 10px;">
                            <div class="col s12 center-align">
                                <span style="color: ${genderColor}; font-size: 2.5rem; font-weight: 900; -webkit-text-stroke: 3px ${genderColor}; text-shadow: 1px 1px 3px #000;">${genderSymbol}</span>
                                <div style="font-size: 0.8rem; color: #b0b0b0; margin-top: -5px;">${tab.is_fertile ? '<span style="color:#4CAF50;">Fertile</span>' : '<span style="color:#F44336;">Infertile</span>'}</div>
                            </div>
                        </div>

                        <div class="row" style="margin: 0;">
                            <div class="col s6 left-align" style="padding-right: 5px;">
                                <div style="font-size: 0.9rem; color: #b0b0b0;">Health: <span style="color: #fff; font-weight: bold;">100%</span></div>
                                <div style="font-size: 0.9rem; color: #b0b0b0; margin-top: 5px;">XP: <span style="color: #fff; font-weight: bold;">${xp}</span></div>
                            </div>
                            
                            <div class="col s6 right-align" style="padding-left: 5px;">
                                <div style="font-size: 0.9rem; color: #b0b0b0;">Age: <span style="color: #fff; font-weight: bold;">${age}</span></div>
                                <div style="font-size: 0.9rem; color: #b0b0b0; margin-top: 5px;">Stable: <span style="color: #fff; font-weight: bold;">${stableLoc}</span></div>
                            </div>
                        </div>

                    </div>
                    <div class="collapsible-body col s12 panel item" id="${HorseID}">
                        <div class="col s4 panel-col item" onclick="SelectHorse(${HorseID}, '${stableLoc}')">
                            <h6 class="grey-text title">Take Out</h6>
                        </div>
                        <div class="col s4 panel-col item" onclick="TransferHorse(${HorseID}, '${HorseName}')">
                            <h6 class="grey-text title">Transfer</h6>
                        </div>
                        <div class="col s4 panel-col item" onclick="SellHorse(${HorseID})">
                            <h6 class="grey-text title">Sell</h6>
                        </div>
                    </div>
                </li> 
            `);

            // Attach Click Event to HEADER to load preview when expanded
            $(`#page_myhorses .scroll-container .collapsible #${uniqueHeaderID}`).on('click', function () {
                $('.selected').removeClass("selected");
                $(this).addClass("selected"); // Highlight header? or just load preview
                $.post('https://devchacha-stable/loadMyHorse', JSON.stringify({ IdHorse: HorseID, horseModel: HorseIdModel, HorseComp: componentsh }));
            });
        }
    }

});

// function confirm(shouldSpawn)
function confirm(shouldSpawn) {
    var doSpawn = shouldSpawn === true; // Force boolean

    // Calculate Total Cost
    var totalCost = 0;
    for (var cat in currentComponents) {
        if (currentComponents[cat] !== initialComponents[cat]) {
            totalCost += getItemPrice(currentComponents[cat]);
        }
    }

    $.post('https://devchacha-stable/CloseStable', JSON.stringify({ spawn: doSpawn, customized: hasCustomized, cost: totalCost }));

    $('#button-customization').addClass("disabled");
    $('#page_myhorses .scroll-container .collapsible').html('');
    //$('#page_shop .scroll-container .collapsible').html('');
    $("#creatormenu").fadeOut(500);
}

// ...

function SelectHorse(horseId, stableLoc) {
    // Check if horse is in current stable (case-insensitive)
    var stableLocLower = (stableLoc || "").toLowerCase().replace(/\s+/g, '');
    var currentLocLower = (currentLocation || "").toLowerCase().replace(/\s+/g, '');

    if (stableLoc && stableLocLower !== currentLocLower) {
        // Trigger notification via Lua
        $.post('https://devchacha-stable/notify', JSON.stringify({
            type: 'error',
            msg: `Your horse is not here! It is stabled at ${stableLoc}.`
        }));
        confirm(false); // Close the UI
        return;
    }

    $.post('https://devchacha-stable/selectHorse', JSON.stringify({ horseID: horseId }));
    // Auto-confirm/close to take out horse with SPAWN = true
    confirm(true);
}

function loadHorse(element) {
    var horseModel = $(element).attr('id');
    if (horseModel) {
        $.post('https://devchacha-stable/loadHorse', JSON.stringify({ horseModel: horseModel }));
    }
}

function TransferHorse(horseId, horseName) {
    // Send to Lua to handle transfer (will show input dialog for player ID)
    $.post('https://devchacha-stable/transferHorse', JSON.stringify({
        horseID: horseId,
        horseName: horseName
    }));
}

function SellHorse(horseId) {
    // Send to Lua for confirmation dialog
    $.post('https://devchacha-stable/confirmSellHorse', JSON.stringify({ horseID: horseId }));
}

function buyHorseWithGender(model, price) {
    var gender = $(`.gender-select[data-model='${model}'] .gender-btn.active`).data('gender') || 'Male';

    $.post('https://devchacha-stable/BuyHorse', JSON.stringify({
        ModelH: model,
        Dollar: price,
        Gender: gender,
        Shop: currentLocation
    }));
    confirm();
}

// Gender Button Listener
$(document).on('click', '.gender-btn', function (e) {
    e.stopPropagation(); // Prevent loading horse preview when clicking gender
    var parent = $(this).closest('.gender-select');
    parent.find('.gender-btn').removeClass('active');
    $(this).addClass('active');

    // Get horse name and gender for notification
    var gender = $(this).data('gender');
    var horseModel = parent.data('model');
    // Try to find horse name from the parent item
    var horseName = parent.closest('.item').find('.title').first().text() || horseModel;

    // Notify via Lua
    $.post('https://devchacha-stable/notify', JSON.stringify({
        type: 'inform',
        msg: gender + ' ' + horseName + ' selected'
    }));
});

// Customization Arrows Logic
$(document).on('click', '.button-left', function (e) {
    var $input = $(this).siblings('input.input-number');
    var val = parseInt($input.val()) || 0;
    var min = parseInt($input.attr('min')) || 0;
    var max = parseInt($input.attr('max')) || 100;

    if (val > min) {
        val--;
        $input.val(val);
        updateCustomizationUI($(this), val, max);
        triggerCustomizationUpdate($input.attr('id'), val);
    }
});

$(document).on('click', '.button-right', function (e) {
    var $input = $(this).siblings('input.input-number');
    var val = parseInt($input.val()) || 0;
    var min = parseInt($input.attr('min')) || 0;
    var max = parseInt($input.attr('max')) || 100;

    if (val < max) {
        val++;
        $input.val(val);
        updateCustomizationUI($(this), val, max);
        triggerCustomizationUpdate($input.attr('id'), val);
    }
});

function updateCustomizationUI($btn, val, max) {
    // Find the title element in the parent panel
    var $panel = $btn.closest('.panel');
    var $title = $panel.find('.title');
    // Extract base text (e.g., "Saddle Cloth")
    var currentText = $title.text();
    // Regex to get name before numbers
    var baseText = currentText.replace(/[0-9\/$ ()]+/g, '').trim();

    var price = getItemPrice(val);
    var priceText = price > 0 ? ` ($${price})` : "";

    // Update text to "Name Val/Max ($Price)"
    $title.text(`${baseText} ${val}/${max}${priceText}`);
}

function triggerCustomizationUpdate(category, value) {
    hasCustomized = true;
    currentComponents[category] = value;
    // Categories: Saddlecloths, Saddles, Stirrups, AcsHorn, Bags, HorseTails, Manes, AcsLuggage
    // Lua expects: { id: value }
    $.post(`https://devchacha-stable/${category}`, JSON.stringify({ id: value }));
}

