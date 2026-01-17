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

                            <div id="${_}" onmouseenter="loadHorse(this)" class="col s12 panel item">

                                <div class="col s6 panel-col item">
                                    <h6 class="grey-text title" style="color:white;">${HorseName}</h6>
                                </div>          

                                <div class="buy-buttons center-align">                                       
                                    <button class="btn-small"  onclick="buyHorse('${_}', ${priceDolar}, false)">
                                        <img src="img/money.png"><span class="horse-price">${priceDolar}</span>
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
            $('.collapsible').collapsible();
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
            let genderIcon = gender == 'Female' ? 'venus' : 'mars';
            let genderColor = gender == 'Female' ? 'pink' : 'lightblue';

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
                                <i class="fas fa-${genderIcon}" style="color: ${genderColor}; font-size: 1.5rem;"></i>
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
                        <div class="col s6 panel-col item" onclick="SelectHorse(${HorseID})">
                            <h6 class="grey-text title">Select</h6>
                        </div>
                        <div class="col s6 panel-col item" onclick="SellHorse(${HorseID})">
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

$('.menu-selectb').on('click', function () {

    $(`#${currentPage}`).hide();

    currentPage = $(this).data('target');
    $(`#${currentPage}`).show();

    $('.menu-selectb.active').removeClass('active');
    $(this).addClass('active');
});

$(".button-right").on('click', function () {
    var inputElement = $(this).parent().find('input');
    var component = $(inputElement).attr('id');

    var value = Number($(inputElement).attr('value'));
    // value = Number(String.split(value, '/')[0]);
    var nValue = value + 1;

    var min = $(inputElement).attr('min');
    var max = $(inputElement).attr('max');

    if (nValue > max) {
        nValue = min;
    }

    $(inputElement).attr('value', nValue);

    var titleElement = $(this).parent().parent().find('.grey-text');
    var text = titleElement.text();
    //  var component = text.split(' ')[0];
    titleElement.text(component + ' ' + nValue + '/' + max);
    $.post('https://devchacha-stable/' + component, JSON.stringify({ id: nValue }));
});

$(".button-left").on('click', function () {
    var inputElement = $(this).parent().find('input');
    var component = $(inputElement).attr('id');

    var value = Number($(inputElement).attr('value'));
    // value = Number(String.split(value, '/')[0]);

    var nValue = value - 1;

    var min = $(inputElement).attr('min');
    var max = $(inputElement).attr('max');

    if (nValue < min) {
        nValue = max;
    }

    $(inputElement).attr('value', nValue);

    var titleElement = $(this).parent().parent().find('.grey-text');
    var text = titleElement.text();
    //  var component = text.split(' ')[0];
    titleElement.text(component + ' ' + nValue + '/' + max);
    $.post('https://devchacha-stable/' + component, JSON.stringify({ id: nValue }));
});

$(".input-number").on("change paste keyup", function () {

    var min = Number($(this).attr('min'));
    var max = Number($(this).attr('max'));

    var value = $(this).val();

    if (value == '' || value < min) {
        value = min;
        $(this).val(value);
    }

    if (value > max) {
        value = max;
        $(this).val(value);
    }

    var titleElement = $(this).parent().parent().find('.grey-text');
    var text = titleElement.text();
    var component = text.split(' ')[0];

    titleElement.text(component + ' ' + value + '/' + max);

});

function buyHorse(Modelhor, price, isGold) {
    $('#button-customization').addClass("disabled");
    $('#page_myhorses .scroll-container .collapsible').html('');
    //$('#page_shop .scroll-container .collapsible').html('');
    $("#creatormenu").fadeOut(500);

    if (isGold) {
        $.post('https://devchacha-stable/BuyHorse', JSON.stringify({ ModelH: Modelhor, Gold: price, IsGold: isGold }));
    } else {
        $.post('https://devchacha-stable/BuyHorse', JSON.stringify({ ModelH: Modelhor, Dollar: price, IsGold: isGold }));
    }
}


function SelectHorse(IdHorse) {
    $.post('https://devchacha-stable/selectHorse', JSON.stringify({ horseID: IdHorse }))
}

function loadHorse(element) {
    var model = $(element).attr('id');
    $.post('https://devchacha-stable/loadHorse', JSON.stringify({ horseModel: model }));
}


function SellHorse(IdHorse) {
    $.post('https://devchacha-stable/sellHorse', JSON.stringify({ horseID: IdHorse }))

    $('#button-customization').addClass("disabled");
    $('#page_myhorses .scroll-container .collapsible').html('');
    //$('#page_shop .scroll-container .collapsible').html('');
    $("#creatormenu").fadeOut(500);

}
