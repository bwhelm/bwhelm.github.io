
// Script to filter sections of webpage
function openSection(secName) {
    var i;
    // Hide all "sectionDiv"
    var secItems = document.getElementsByClassName("sectionDiv");
    for (i = 0; i < secItems.length; i++) {
        secItems[i].style.display = "none";
    }
    document.getElementById(secName).style.display = "block";
    var secButtons = document.getElementsByClassName("secNav");
    for (var i = 0; i < secButtons.length; i++) {
        w3RemoveClass(secButtons[i], "w3-light-grey");
        if (secButtons[i].className.indexOf("secButton" + secName) > -1) {
            w3AddClass(secButtons[i], "w3-light-grey");
        }
    }
}

// Script to filter items by category in bibliography
function filterBibliography(bibName) {
    var bibItems, bibButtons, i;
    // Add "w3-teal" class to button that was clicked, removing it from others
    bibButtons = document.getElementsByClassName("bibNav");
    for (i = 0; i < bibButtons.length; i++) {
        w3RemoveClass(bibButtons[i], "w3-teal");
        if (bibButtons[i].className.indexOf(bibName) > -1) {
            w3AddClass(bibButtons[i], "w3-teal");
        }
    }
    bibItems = document.getElementsByClassName("filterBib");
    if (bibName == "showall") bibName = "";
    // Add the "show" class (display:block) to the filtered elements, and remove the "show" class from the elements that are not selected
    for (i = 0; i < bibItems.length; i++) {
        w3RemoveClass(bibItems[i], "show");
        if (bibItems[i].className.indexOf(bibName) > -1) {
            w3AddClass(bibItems[i], "show");
        }
    }
}

// Show filtered elements
function w3AddClass(element, name) {
    var i, arr1, arr2;
    arr1 = element.className.split(" ");
    arr2 = name.split(" ");
    for (i = 0; i < arr2.length; i++) {
        if (arr1.indexOf(arr2[i]) == -1) {
            element.className += " " + arr2[i];
        }
    }
}

// Hide elements that are not selected
function w3RemoveClass(element, name) {
    var i, arr1, arr2;
    arr1 = element.className.split(" ");
    arr2 = name.split(" ");
    for (i = 0; i < arr2.length; i++) {
        while (arr1.indexOf(arr2[i]) > -1) {
            arr1.splice(arr1.indexOf(arr2[i]), 1);
        }
    }
    element.className = arr1.join(" ");
}
