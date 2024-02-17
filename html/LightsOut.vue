<script setup>
import { reactive, watch } from 'vue';

const BOARD_WIDTH = 6;
const BOARD_HEIGHT = 6;

let cells = reactive(Array.from({ length: BOARD_WIDTH * BOARD_HEIGHT }, (_, i) => ( {
    id: i,
    active: false,
    clickMe: false,
    phase2Clicked: false,
})));

let model = reactive({
    setupCustomBoard: false,
    showHints: true,
    strategyPhase: 1,
});

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
            cells[remainingIds[i]].clickMe = true;
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
    <h1>6x6 Trainer</h1>
    <div>
        <label title="allows clicking one cell without affecting others">
            <input type="checkbox" v-model="model.setupCustomBoard" />
            Setup Custom Board
        </label>
    </div>
    <div>
        <label>
            <input type="checkbox" v-model="model.showHints" />
            Show Hints
        </label>
        <button @click="calculateHints">Calculate Hints</button>
    </div>
    <div>
        <button @click="randomizeBoard">Randomize</button>
    </div>
    <div>
        <button @click="clearBoard">Clear</button>
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
        </div>
    </div>
</template>

<style>
    body {
        font-family: ui-sans-serif, system-ui;
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
</style>
