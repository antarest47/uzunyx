import QtQuick

// A mouse pointer (white arrow with a dark outline) for the focus previews.
Canvas {
    width: 14
    height: 20

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.beginPath();
        ctx.moveTo(1, 1);
        ctx.lineTo(1, 16);
        ctx.lineTo(5, 12.5);
        ctx.lineTo(8, 19);
        ctx.lineTo(10.5, 18);
        ctx.lineTo(7.5, 11.5);
        ctx.lineTo(12.5, 11.5);
        ctx.closePath();
        ctx.fillStyle = "white";
        ctx.strokeStyle = "#111318";
        ctx.lineWidth = 1.2;
        ctx.lineJoin = "round";
        ctx.fill();
        ctx.stroke();
    }
}
