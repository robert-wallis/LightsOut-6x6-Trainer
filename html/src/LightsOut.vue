<script setup>
import { reactive, watch } from 'vue';

const BOARD_WIDTH = 6;
const BOARD_HEIGHT = 6;

let cells = reactive(Array.from({ length: BOARD_WIDTH * BOARD_HEIGHT }, (_, i) => ( {
    id: i,
    active: false,
    clickMe: false,
    phase2Clicked: false,
    arrow1: false,
    arrow2: false,
})));

let model = reactive({
    setupCustomBoard: false,
    showHints: true,
    strategyPhase: 1,
});

randomizeBoard();
watch(model.showHints, calculateHints);

function onCellClick(cell) {
    toggleCell(cells[cell.id]);
    calculateHints();
}

function toggleCell(cell) {
    cell.active = !cell.active;
    if (model.strategyPhase === 2) {
        if (!cell.clickMe) {
            // bad click, please undo
            cell.clickMe = true;
        } else {
            cell.phase2Clicked = !cell.phase2Clicked;
        }
    }
    if (!model.setupCustomBoard) {
        toggleAdjacent(cell);
    }
}

function toggleAdjacent(cell) {
    let left = cellLeft(cell.id);
    if (left) {
        left.active = !left.active;
    }
   
    let right = cellRight(cell.id);
    if (right) {
        right.active = !right.active;
    }

    let up = cellUp(cell.id);
    if (up) {
        up.active = !up.active;
    }

    let down = cellDown(cell.id);
    if (down) {
        down.active = !down.active;
    }
}

function cellLeft(ofId) {
    const x = ofId % BOARD_WIDTH;
    if (x > 0) {
        return cells[ofId - 1];
    }
    return null;
}

function cellRight(ofId) {
    const x = ofId % BOARD_WIDTH;
    if (x < BOARD_WIDTH - 1) {
        return cells[ofId + 1];
    }
    return null;
}

function cellUp(ofId) {
    const y = Math.floor(ofId / BOARD_HEIGHT);
    if (y > 0) {
        return cells[ofId - BOARD_WIDTH];
    }
    return null;
}

function cellDown(ofId) {
    const y = Math.floor(ofId / BOARD_HEIGHT);
    if (y < BOARD_HEIGHT - 1) {
        return cells[ofId + BOARD_WIDTH];
    }
    return null;
}


function randomizeBoard() {
    model.strategyPhase = 1;
    cells.forEach(cell => {
        cell.active = Math.random() > 0.5;
    });
    calculateHints();
}

function clearBoard() {
    model.strategyPhase = 1;
    cells.forEach(cell => {
        cell.active = false;
    });
    calculateHints();
}

function calculateHints() {
    // clear all hints
    cells.forEach(cell => {
        if (model.strategyPhase === 2) {
            // don't clear the top row if we are in phase 3
            if (cell.id >= BOARD_WIDTH) {
                cell.clickMe = false;
            }
        } else {
            cell.clickMe = false;
            cell.phase2Clicked = false;
            cell.arrow1 = false;
            cell.arrow2 = false;
        }
    });

    if (model.strategyPhase === 2) {
        var allPhase2Clicked = true;
        for (let i = 0; i < BOARD_WIDTH; i++) {
            if (cells[i].clickMe) {
                if (!cells[i].phase2Clicked) {
                    allPhase2Clicked = false;
                }
            }
        }
        if (allPhase2Clicked) {
            model.strategyPhase = 3;
            for (let i = 0; i < BOARD_WIDTH; i++) {
                cells[i].clickMe = false;
            }
        }
    }

    var topDownClear = true;

    // top down clear strategy
    for (let row = 0; row < BOARD_HEIGHT - 1; row++) {
        var anyActive = false;
        for (let col = 0; col < BOARD_WIDTH; col++) {
            const cell = cells[row * BOARD_WIDTH + col];
            if (cell.active) {
                anyActive = true;
                let down = cellDown(cell.id);
                if (down) {
                    down.clickMe = true;
                }
            }
        } 
        if (anyActive) {
            topDownClear = false;
            break;
        }
    }

    // last row clear strategy
    if (topDownClear) {
        model.strategyPhase = 2;
        let row = BOARD_HEIGHT - 1;
        var anyActive = false;
        var idsToTick = [];
        for (let col = 0; col < BOARD_WIDTH; col++) {
            const cell = cells[row * BOARD_WIDTH + col];
            if (cell.active) {
                anyActive = true;
                cell.arrow1 = true;
                cell.arrow2 = true;
                let addIds = topRowCellsForBottomRowCell(cell.id);
                idsToTick.push(...addIds);
            }
        }
        // count the number of times an id is in the array
        var countIdsToTick = {};
        for (let i = 0; i < idsToTick.length; i++) {
            countIdsToTick[idsToTick[i]] = (countIdsToTick[idsToTick[i]] || 0) + 1;
        }
        // if the count is even, then we can ignore it because clicking twice cancels itself out
        var remainingIds = []
        for (let i = 0; i < idsToTick.length; i++) {
            if (countIdsToTick[idsToTick[i]] % 2 !== 0) {
                remainingIds.push(idsToTick[i]);
            }
        }
        var anyPhase2Ticked = false;
        // finally tick the remaining ids
        for (let i = 0; i < remainingIds.length; i++) {
            let cell = cells[remainingIds[i]];
            cell.clickMe = true;
            anyPhase2Ticked = true;
        }
        if (anyPhase2Ticked) {
            model.strategyPhase = 2;
        } else {
            model.strategyPhase = 3;
        }

        var allClear = true;
        cells.forEach(cell => {
            if (cell.active) {
                allClear = false;
            }
        });
        if (allClear) {
            model.strategyPhase = 1;
            cells.forEach(cell => cell.clickMe = false);
        }
    }
}

// this is the meat of the strategy
// if you are left with cells at the bottom
// then start from the top again ticking these cells off
// now when you do the original strategy again, it will be clear at the bottom
// https://gaming.stackexchange.com/a/339293/311986
function topRowCellsForBottomRowCell(cellId) {
    switch (cellId) {
    case 30: return [0, 2];
    case 31: return [3];
    case 32: return [0, 4];
    case 33: return [1, 5];
    case 34: return [2];
    case 35: return [3, 5];
    }
    return []
}

</script>

<template>
    <h1>6x6 Lights Out Trainer</h1>
    <p>Solve the 6x6 Lights Out puzzle every time, even if it's random in this 3 stage process.</p>
    <p>This puzzle is used in the bank in Nopixel 4.0 RP.</p>
    <div>
        <button @click="randomizeBoard">Randomize</button>
    </div>
    <div>
        <label title="allows clicking one cell without affecting others">
            <input type="checkbox" v-model="model.setupCustomBoard" />
            Setup Custom Board
        </label>
        <button @click="clearBoard">Clear</button>
    </div>
    <div>
        <label>
            <input type="checkbox" v-model="model.showHints" />
            Show Hints
        </label>
        <button @click="calculateHints">Calculate Hints</button>
    </div>
    <div class="trainer">
        <div class="tips">
            <h2>Strategy Phase: {{ model.strategyPhase }}</h2>
            <p v-if="model.strategyPhase == 1">
               First click all the cells one below the topmost active cell. 
            </p>
            <p v-if="model.strategyPhase == 2">
               Now click the top row cells that are marked. 
            </p>
            <p v-if="model.strategyPhase == 3">
               Finally, do the same strategy as in phase 1, but this time it will be clear at the bottom if you did it right. 
            </p>
        </div>
        <div class="grid">
            <div class="cell" v-for="cell in cells" :class="{ active: cell.active }" @click="onCellClick(cell)">
                <div class="cellName">{{ cell.id + 1 }}</div>
                <div class="clickMe" :class="{ active: model.showHints && cell.clickMe, phase2Clicked: model.showHints && cell.phase2Clicked }"></div>
            </div>
            <svg class="arrows" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:serif="http://www.serif.com/" width="500" height="500" viewBox="0 0 378 378" version="1.1" xml:space="preserve" style="fill-rule:evenodd;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:1.5;">
              <path :class="{ phase2Arrow: cells[30].arrow1 }" id="arrow-1-1" d="M6.246,76.607l20.004,-22.607l6.083,29.568c-4.781,-8.262 -17.825,-11.743 -26.087,-6.961Z"/>
              <path :class="{ phase2Arrow: cells[30].arrow1 }" d="M18.75,324.75c0,0 -11.956,-174.587 1.932,-249.88" style="fill:none;stroke:#000;stroke-width:9px;"/>
              <path :class="{ phase2Arrow: cells[30].arrow2 }" id="arrow-1-3" d="M122.567,68.701l25.933,-15.451l-3.199,30.017c-2.042,-9.325 -13.409,-16.608 -22.734,-14.566Z"/>
              <path :class="{ phase2Arrow: cells[30].arrow2 }" d="M40.5,324c0,0 27.228,-139.501 96.347,-252.563" style="fill:none;stroke:#000;stroke-width:9px;"/>
              <path :class="{ phase2Arrow: cells[31].arrow1 }" id="arrow-2-4" d="M184.032,69.392l25.968,-15.392l-3.267,30.01c-2.021,-9.33 -13.371,-16.639 -22.701,-14.618Z"/>
              <path :class="{ phase2Arrow: cells[31].arrow1 }" d="M94.5,324.75c0,0 33.979,-139.523 103.806,-252.589" style="fill:none;stroke:#000;stroke-width:9px;"/>
              <path :class="{ phase2Arrow: cells[32].arrow1 }" id="arrow-3-1" d="M45.296,83.053l-4.796,-29.803l26.721,14.045c-9.421,-1.541 -20.383,6.338 -21.925,15.758Z"/>
              <path :class="{ phase2Arrow: cells[32].arrow1 }" d="M145.5,324c0,0 -26.39,-154.311 -92.393,-253.211" style="fill:none;stroke:#000;stroke-width:9px;"/>
              <path :class="{ phase2Arrow: cells[32].arrow2 }" id="arrow-3-5" d="M255.194,68.583l26.431,-14.583l-4.192,29.894c-1.732,-9.387 -12.851,-17.043 -22.239,-15.311Z"/>
              <path :class="{ phase2Arrow: cells[32].arrow2 }" d="M168,324.75c0,0 19.7,-129.547 101.376,-252.959" style="fill:none;stroke:#000;stroke-width:9px;"/>
              <path :class="{ phase2Arrow: cells[33].arrow1 }" id="arrow-4-2" d="M82.963,81.895l11.537,-27.895l15.394,25.967c-7.215,-6.251 -20.68,-5.287 -26.931,1.928Z"/>
              <path :class="{ phase2Arrow: cells[33].arrow1 }" d="M207,324.75c0,0 -97.028,-123.958 -110.957,-249.205" style="fill:none;stroke:#000;stroke-width:9px;"/>
              <path :class="{ phase2Arrow: cells[33].arrow2 }" id="arrow-4-6" d="M313.685,79.398l16.315,-25.398l10.529,28.291c-5.987,-7.434 -19.41,-8.881 -26.844,-2.893Z"/>
              <path :class="{ phase2Arrow: cells[33].arrow2 }" d="M233.25,324.75c0,0 77.711,-128.751 94.436,-249.274" style="fill:none;stroke:#000;stroke-width:9px;"/>
              <path :class="{ phase2Arrow: cells[34].arrow1 }" id="arrow-5-3" d="M160.139,82.933l8.611,-28.933l17.98,24.248c-7.819,-5.476 -21.114,-3.134 -26.591,4.685Z"/>
              <path :class="{ phase2Arrow: cells[34].arrow1 }" d="M281.625,324.75c0,0 -86.225,-142.538 -109.128,-249.478" style="fill:none;stroke:#000;stroke-width:9px;"/>
              <path :class="{ phase2Arrow: cells[35].arrow1 }" id="arrow-6-4" d="M221.476,81.046l11.774,-27.796l15.173,26.097c-7.162,-6.312 -20.635,-5.462 -26.947,1.699Z"/>
              <path :class="{ phase2Arrow: cells[35].arrow1 }" d="M333.75,324c0,0 -87.126,-141.74 -99.14,-249.193" style="fill:none;stroke:#000;stroke-width:9px;"/>
              <path :class="{ phase2Arrow: cells[35].arrow2 }" id="arrow-6-6" d="M350.604,82.152l10.896,-28.152l15.984,25.608c-7.356,-6.084 -20.796,-4.812 -26.88,2.544Z"/>
              <path :class="{ phase2Arrow: cells[35].arrow2 }" d="M358.5,324.75c0,0 14.366,-133.215 5.035,-249.246" style="fill:none;stroke:#000;stroke-width:9px;"/>
            </svg>
        </div>
    </div>
    <footer>Copyright &copy; 2024 <a href="https://smilingrob.com/">Robert Wallis</a></footer>
</template>

<style>
    body {
        font-family: ui-sans-serif, system-ui;
        background-color: #222;
        color: #EEE;
    }
    a {
        color: #33db33;
    }
    .trainer {
        display: flex;
        flex-direction: row;
        width: 800px;
    }
    .tips {
    }
    .grid {
        display: flex;
        flex-wrap: wrap;
        width: calc(84px * 6);
        min-width: calc(84px * 6);
    }
    .cell {
        position: relative;
        display: flex;
        justify-content: center;
        align-items: center;
        width: 80px;
        height: 80px;
        margin: 2px;
        --webkit-user-select: none;
        user-select: none;
        color: #DDD;
        background-color: #a1a1a1;
    }
    .cell.active {
        background-color: #00db00;
    }
    .cell .cellName {
        position: absolute;
        z-index: 3;
        font-size: 1rem;
    }
    .cell .clickMe.active {
        position: absolute;
        z-index: 2;
        width: 30px;
        height: 30px;
        background-color: #000;
        border-radius: 50%;
    }
    .cell .clickMe.phase2Clicked {
        background-color: rgba(0, 0, 0, 0.2);
    }
    .arrows {
        position: absolute;
        z-index: 10;
        pointer-events: none;
    }
    .arrows path {
        display: none;
    }
    .arrows path.phase2Arrow {
        display: block;
    }
</style>
