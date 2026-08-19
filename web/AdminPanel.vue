<!-- plugins/oblsk_admin/web/AdminPanel.vue -->
<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import Obelisk from '@/obelisk.js'
import ComingSoon from './ComingSoon.vue'
import OrganisationsTab from './OrganisationsTab.vue'
import PlayersTab from './PlayersTab.vue'
import ModerationTab from './ModerationTab.vue'
import VehiclesTab from './VehiclesTab.vue'
import ItemsTab from './ItemsTab.vue'
import CategoriesTab from './CategoriesTab.vue'
import InteractionsTab from './InteractionsTab.vue'
import JobsTab from './JobsTab.vue'
import SchedulerTab from './SchedulerTab.vue'
import FishingTab from '../../oblsk_fishing/web/FishingTab.vue'
import HuntingTab from '../../oblsk_hunting/web/HuntingTab.vue'
import PrintersTab from './PrintersTab.vue'

const TABS = [
  ['players', 'Players'], ['moderation', 'Moderation'], ['organisations', 'Organisations'],
  ['vehicles', 'Vehicles'], ['interactions', 'Interactions'], ['blips', 'Blips'],
  ['locations', 'Locations'], ['items', 'Items'], ['categories', 'Categories'], ['jobs', 'Jobs'], ['scheduler', 'Scheduler'], ['fishing', 'Fishing'], ['hunting', 'Hunting'], ['printers', 'Printers'], ['economy', 'Economy'],
  ['server', 'Server'], ['audit', 'Audit log'],
]

const activeTab = ref('organisations')

// This is a routed page ('/Admin'), not a global element, so router.push
// to the same path won't remount the component and re-run onMounted — the
// panel's own open/closed state has to be driven explicitly by
// 'admin:client:panel-open'/'panel-close' (client/main.lua), not inferred
// from mount lifecycle. In dev, no game client ever sends that signal, so
// default to open so the route renders standalone in a browser — same
// posture as every other routed plugin page's import.meta.env.DEV fixture
// (e.g. Shop.vue's debugShop()).
const open = ref(import.meta.env.DEV)

// Plugin-specific close event, same reasoning as before the global-element
// removal: the generic 'core:client:close' NUI callback only releases NUI
// focus and (for global elements) resets visibility - for a routed page it
// wouldn't touch this component's `open` state at all. Emitting our own
// event tells client/main.lua's local `panelOpen` to stay in sync.
function close() {
  open.value = false
  Obelisk.emit('admin:client:close-panel', {})
}

function onPanelOpen() { open.value = true }
function onPanelClose() { open.value = false }

// core's global ESC watcher only closes global elements (WebView.closeAll()),
// never routed pages - so this panel needs its own Escape handling, same as
// Shop.vue/Garage.vue do for theirs.
function onKeydown(e) {
  if (e.key === 'Escape' && open.value) close()
}

onMounted(() => {
  Obelisk.on('admin:client:panel-open', onPanelOpen)
  Obelisk.on('admin:client:panel-close', onPanelClose)
  window.addEventListener('keydown', onKeydown)
})

onBeforeUnmount(() => {
  Obelisk.off('admin:client:panel-open', onPanelOpen)
  Obelisk.off('admin:client:panel-close', onPanelClose)
  window.removeEventListener('keydown', onKeydown)
})
</script>

<template>
  <div v-if="open" class="absolute inset-0 flex flex-col" style="padding: 2.5vh 2vw">
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
      <VehiclesTab v-else-if="activeTab === 'vehicles'" />
      <ItemsTab v-else-if="activeTab === 'items'" />
      <CategoriesTab v-else-if="activeTab === 'categories'" />
      <JobsTab v-else-if="activeTab === 'jobs'" />
      <SchedulerTab v-else-if="activeTab === 'scheduler'" />
      <FishingTab v-else-if="activeTab === 'fishing'" />
      <HuntingTab v-else-if="activeTab === 'hunting'" />
      <PrintersTab v-else-if="activeTab === 'printers'" />
      <InteractionsTab v-else-if="activeTab === 'interactions'" />
      <ComingSoon v-else :label="TABS.find(([k]) => k === activeTab)[1]" />
    </div>
  </div>
</template>
