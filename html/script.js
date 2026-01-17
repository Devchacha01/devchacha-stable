$('#creatormenu').fadeOut(0);


window.addEventListener('message', function (event) {
    if (event.data.action == "show") {
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

        if (event.data.action == "hide") {
            $("#creatormenu").fadeOut(500);
        }
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
                                <span style="color: ${genderColor}; font-size: 2.5rem; font-weight: bold;">${genderSymbol}</span>
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
                        <div class="col s4 panel-col item" onclick="SelectHorse(${HorseID})">
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

function confirm() {
    $.post('https://devchacha-stable/CloseStable')

    $('#button-customization').addClass("disabled");
    $('#page_myhorses .scroll-container .collapsible').html('');
    //$('#page_shop .scroll-container .collapsible').html('');
    $("#creatormenu").fadeOut(500);
}

var currentPage = 'page_myhorses';


// Menu Navigation - Add Transfers Tab Handler
$('.menu-selectb').on('click', function () {
    $(`#${currentPage}`).hide();

    currentPage = $(this).data('target');
    $(`#${currentPage}`).show();

    $('.menu-selectb.active').removeClass('active');
    $(this).addClass('active');

    // Load Pending Transfers when tab is clicked
    if (currentPage === 'page_transfers') {
        $.post('https://devchacha-stable/getPendingTransfers', JSON.stringify({}));
    }
});

// Listener for Pending Transfers Data
window.addEventListener('message', function (event) {
    // ... existing listeners ...
    if (event.data.action === "updatePendingTransfers") {
        const transfers = event.data.transfers;
        const $list = $('#transfers-list');
        $list.html('');

        if (transfers.length === 0) {
            $list.append(`
                <li>
                    <div class="collapsible-header col s12 panel">
                        <div class="col s12 panel-title">
                            <h6 class="grey-text">No pending transfers.</h6>
                        </div>
                    </div>
                </li>
            `);
        } else {
            transfers.forEach(function (t) {
                const priceText = t.price > 0 ? `$${t.price}` : 'Free';
                $list.append(`
                    <li>
                        <div class="collapsible-header col s12 panel" style="display: block; min-height: 80px; padding: 10px;">
                            <div class="row" style="margin: 0;">
                                <div class="col s12">
                                    <h6 class="grey-text" style="color: white; font-weight: bold;">${t.horse_name}</h6>
                                    <span class="grey-text" style="font-size: 0.8rem;">From: ${t.sender_name}</span>
                                </div>
                            </div>
                            <div class="row" style="margin: 5px 0 0 0; display: flex; align-items: center; justify-content: space-between;">
                                <div class="col s4">
                                    <span style="color: #4CAF50; font-weight: bold;">${priceText}</span>
                                </div>
                                <div class="col s8 right-align">
                                    <button class="btn-small green waves-effect" onclick="respondTransfer(${t.id}, true)">Accept</button>
                                    <button class="btn-small red waves-effect" onclick="respondTransfer(${t.id}, false)">Decline</button>
                                </div>
                            </div>
                        </div>
                    </li>
                `);
            });
        }
        $('#transfers-list').collapsible();
    }
    // ... existing listeners ...
});

// Respond to Transfer
function respondTransfer(transferId, accepted) {
    $.post('https://devchacha-stable/respondTransfer', JSON.stringify({
        transferId: transferId,
        accepted: accepted
    }));

    // Optimistically remove from UI or wait for refresh
    setTimeout(function () {
        $.post('https://devchacha-stable/getPendingTransfers', JSON.stringify({}));
    }, 500);
}


function TransferHorse(horseId, horseName) {
    // Simplified: Just close UI and trigger client startTransferNUICallback
    // The client script will then handle the input via chat command or rsg-input if available

    $.post('https://devchacha-stable/startTransfer', JSON.stringify({
        horseID: horseId,
        horseName: horseName
    }));

    $('#button-customization').addClass("disabled");
    $('#page_myhorses .scroll-container .collapsible').html('');
    $("#creatormenu").fadeOut(500);
}

// Restore missing functions
function loadHorse(element) {
    var model = $(element).attr('id');
    $.post('https://devchacha-stable/loadHorse', JSON.stringify({ horseModel: model }));
}

function SelectHorse(horseId) {
    $.post('https://devchacha-stable/selectHorse', JSON.stringify({ horseID: horseId }));
    // Auto-confirm/close to take out horse
    confirm();
}

function SellHorse(horseId) {
    $.post('https://devchacha-stable/sellHorse', JSON.stringify({ horseID: horseId }));
}

function buyHorseWithGender(model, price) {
    var gender = $(`.gender-select[data-model='${model}'] .gender-btn.active`).data('gender') || 'Male';

    $.post('https://devchacha-stable/BuyHorse', JSON.stringify({
        ModelH: model,
        Dollar: price,
        Gender: gender
    }));
    confirm();
}

// Gender Button Listener
$(document).on('click', '.gender-btn', function (e) {
    e.stopPropagation(); // Prevent loading horse preview when clicking gender
    var parent = $(this).closest('.gender-select');
    parent.find('.gender-btn').removeClass('active');
    $(this).addClass('active');
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
    var baseText = currentText.split(' ')[0];
    if (currentText.includes('Saddle Cloth')) baseText = "Saddle Cloth"; // Special case for space

    // Update text to "Name Val/Max"
    $title.text(`${baseText} ${val}/${max}`);
}

function triggerCustomizationUpdate(category, value) {
    // Categories: Saddlecloths, Saddles, Stirrups, AcsHorn, Bags, HorseTails, Manes, AcsLuggage
    // Lua expects: { id: value }
    $.post(`https://devchacha-stable/${category}`, JSON.stringify({ id: value }));
}

