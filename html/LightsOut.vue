<script setup>
import { reactive } from 'vue';

const BOARD_WIDTH = 6;
const BOARD_HEIGHT = 6;

let cells = reactive(Array.from({ length: BOARD_WIDTH * BOARD_HEIGHT }, (_, i) => ({ id: i, active: false })));
let setupCustomBoard = reactive(false);

function toggleCell(cell) {
    cell.active = !cell.active;
    if (!setupCustomBoard) {
        toggleAdjacent(cell);
    }
}

function toggleAdjacent(cell) {
    const x = cell.id % BOARD_WIDTH;
    const y = Math.floor(cell.id / BOARD_HEIGHT);
    if (x > 0) {
        cells[cell.id - 1].active = !cells[cell.id - 1].active;
    }
    if (x < BOARD_WIDTH - 1) {
        cells[cell.id + 1].active = !cells[cell.id + 1].active;
    }
    if (y > 0) {
        cells[cell.id - 6].active = !cells[cell.id - BOARD_HEIGHT].active;
    }
    if (y < BOARD_HEIGHT - 1) {
        cells[cell.id + 6].active = !cells[cell.id + BOARD_HEIGHT].active;
    }
}

</script>

<template>
    <h1>6x6 Trainer</h1>
    <label>
        <input type="checkbox" v-model="setupCustomBoard" />
        Setup Custom Board
    </label>
    <div class="grid">
        <div class="cell" v-for="cell in cells" :class="{ active: cell.active }" @click="toggleCell(cell)">
            {{ cell.id + 1 }}
        </div>
    </div>
</template>

<style>
    body {
        font-family: ui-sans-serif, system-ui;
    }
    .grid {
        display: flex;
        flex-wrap: wrap;
        width: 504px;
    }
    .cell {
        width: 80px;
        height: 80px;
        display: inline-block;
        margin: 2px;
        --webkit-user-select: none;
        user-select: none;
        color: #DDD;
        background-color: #a1a1a1;
    }
    .cell.active {
        background-color: #00db00;
    }
</style>
