let currentApiary = null;
let updateInterval = null;

window.addEventListener('message', function(event) {
    const data = event.data;

    // Open the Apiary menu
    if (data.action === "openPlantMenu") {
        currentApiary = data.data;

        document.body.style.display = "block";
        updateUI(currentApiary); // Initial display

        // Start polling updates from server
        if (updateInterval) clearInterval(updateInterval);
        updateInterval = setInterval(() => {
            $.post("https://QC-Beekeeper/requestPlantUpdate", JSON.stringify({ apiarieid: currentApiary.id }));
        }, 1500); // every 1.5 seconds
    }

    // Server pushes updated Apiary data
    if (data.action === "updateApiaryData") {
        currentApiary = data.data;
        updateUI(currentApiary);
    }
});

// Updates the UI bars and values
function updateUI(d) {
    $("#health-val").text(d.quality.toFixed(2) + "%");
    $("#health").css("width", d.quality + "%").css("background", getColorByScheme(d.qualityColor));

    $("#water-val").text(d.polneed.toFixed(2) + "%");
    $("#water").css("width", d.polneed + "%").css("background", getColorByScheme(d.polneedColor));

    $("#fertilizer-val").text(d.necneed.toFixed(2) + "%");
    $("#fertilizer").css("width", d.necneed + "%").css("background", getColorByScheme(d.necneedColor));
}


// Simple color schemes
function getColor(percent) {
    if (percent > 50) return "#27ae60"; // Green
    if (percent > 10) return "#f1c40f"; // Yellow
    return "#e74c3c"; // Red
}

function getColorByScheme(scheme) {
    if (scheme === "green") return "#27ae60";
    if (scheme === "yellow") return "#f1c40f";
    return "#e74c3c";
}

// Called from HTML buttons
function Give(type) {
    if (!currentApiary) return;

    if (type === "Pollinate") {
        $.post("https://QC-Beekeeper/PollinateApiary", JSON.stringify({ apiarieid: currentApiary.id }));
    } else if (type === "Nectar") {
        $.post("https://QC-Beekeeper/NectarApiary", JSON.stringify({ apiarieid: currentApiary.id }));
    } else if (type === "Harvest") {
        $.post("https://QC-Beekeeper/HarvestApiary", JSON.stringify({ apiarieid: currentApiary.id, growth: currentApiary.growth }));
    }

    CloseMenu();
}

// Close and stop polling
function CloseMenu() {
    document.body.style.display = "none";
    $.post("https://QC-Beekeeper/CloseMenu", JSON.stringify({}));

    if (updateInterval) {
        clearInterval(updateInterval);
        updateInterval = null;
    }
}

// Escape closes the menu
document.addEventListener('keydown', function(e) {
    if (e.key === "Escape") CloseMenu();
});
