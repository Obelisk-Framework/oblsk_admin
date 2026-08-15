<script setup>
import { ref } from 'vue'
import Obelisk from '@/obelisk.js'
import ComingSoon from './ComingSoon.vue'
import OrganisationsTab from './OrganisationsTab.vue'
import PlayersTab from './PlayersTab.vue'
import ModerationTab from './ModerationTab.vue'

const TABS = [
  ['players', 'Players'], ['moderation', 'Moderation'], ['organisations', 'Organisations'],
  ['vehicles', 'Vehicles'], ['interactions', 'Interactions'], ['blips', 'Blips'],
  ['locations', 'Locations'], ['items', 'Items'], ['economy', 'Economy'],
  ['server', 'Server'], ['audit', 'Audit log'],
]

const activeTab = ref('organisations')

// Plugin-specific close event: the generic 'core:client:close' NUI callback
// only hides the raw webview (SetNuiFocus off) and has no effect on this
// panel's global-element visibility, so it never actually disappears.
// 'admin:client:close-panel' is handled by this plugin's own
// client/main.lua, which knows about and resets the local panelOpen state.
const close = () => Obelisk.emit('admin:client:close-panel', {})
</script>

<template>
  <div class="absolute inset-0 flex flex-col" style="padding: 2.5vh 2vw">
    <div class="flex-1 rounded-2xl border border-white/12 bg-[#0d1012] shadow-2xl overflow-hidden flex flex-col">
      <div class="h-14 px-5 flex items-center justify-between border-b border-white/8 shrink-0">
        <div class="text-[14px] font-semibold">Staff Panel</div>
        <button @click="close" class="h-8 px-3 rounded-lg border border-white/12 text-[11.5px] hover:bg-white/8">Close</button>
      </div>

      <div class="h-11 px-5 flex items-center gap-1 border-b border-white/8 shrink-0 overflow-x-auto">
        <button v-for="[key, label] in TABS" :key="key" @click="activeTab = key"
          class="px-3 py-1.5 rounded-lg text-[12px] transition whitespace-nowrap"
          :class="activeTab === key ? 'text-black font-medium' : 'text-white/45 hover:text-white hover:bg-white/8'"
          :style="activeTab === key ? { background: 'var(--ob-accent)' } : undefined">
          {{ label }}
        </button>
      </div>

      <OrganisationsTab v-if="activeTab === 'organisations'" />
      <PlayersTab v-else-if="activeTab === 'players'" />
      <ModerationTab v-else-if="activeTab === 'moderation'" />
      <ComingSoon v-else :label="TABS.find(([k]) => k === activeTab)[1]" />
    </div>
  </div>
</template>
