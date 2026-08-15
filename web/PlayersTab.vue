<script setup>
import { ref, onMounted, onBeforeUnmount, inject, watch } from 'vue'
import Obelisk from '@/obelisk.js'

const players = ref([])
const kickReason = ref('')
const kickTarget = ref(null)

const DEV_PLAYERS = [
  { source: 1, name: 'Steam_abc123', characterName: 'Jane Doe', ping: 34, coords: { x: 215.3, y: -810.2, z: 30.7 } },
  { source: 2, name: 'Steam_def456', characterName: 'Mark Ito', ping: 58, coords: { x: -48.1, y: -1090.5, z: 26.4 } },
]

const onReply = ({ players: next }) => { players.value = next }

const fetchList = () => {
  if (import.meta.env.DEV) { players.value = DEV_PLAYERS; return }
  Obelisk.emit('admin:client:players-list', {})
}

onMounted(() => {
  Obelisk.on('admin:client:players-reply', onReply)
  fetchList()
})
onBeforeUnmount(() => Obelisk.off('admin:client:players-reply', onReply))

const registry = inject('obelisk:globalElementsRegistry', null)
if (registry) {
  watch(() => registry.get('admin')?.visible, (visible) => { if (visible) fetchList() })
}

const teleportTo = (p) => Obelisk.emit('admin:client:players-teleport-to-player', { targetSource: p.source })
const bring = (p) => Obelisk.emit('admin:client:players-bring-player', { targetSource: p.source })
const spectate = (p) => Obelisk.emit('admin:client:players-spectate', { targetSource: p.source })
const openKick = (p) => { kickTarget.value = p; kickReason.value = '' }
const submitKick = () => {
  Obelisk.emit('admin:client:players-kick', { targetSource: kickTarget.value.source, reason: kickReason.value || 'No reason given' })
  kickTarget.value = null
}
</script>

<template>
  <div class="flex-1 overflow-hidden flex flex-col p-5 gap-3">
    <div class="text-[12.5px] font-medium">Players online · {{ players.length }}</div>
    <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex-1 overflow-y-auto">
      <div v-for="p in players" :key="p.source" class="px-3.5 py-2.5 flex items-center gap-3 border-b border-white/6">
        <span class="ob-mono text-[10px] text-white/35 w-8 shrink-0">#{{ p.source }}</span>
        <span class="min-w-0 flex-1">
          <span class="block text-[12px] truncate">{{ p.characterName || p.name }}</span>
          <span class="block ob-mono text-[9px] text-white/35 truncate">{{ p.name }} · {{ p.ping }}ms</span>
        </span>
        <button @click="teleportTo(p)" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 hover:bg-white/8">GOTO</button>
        <button @click="bring(p)" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 hover:bg-white/8">BRING</button>
        <button @click="spectate(p)" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 hover:bg-white/8">SPEC</button>
        <button @click="openKick(p)" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 text-red-300 hover:bg-red-500/10">KICK</button>
      </div>
      <div v-if="!players.length" class="py-6 text-center text-[11.5px] text-white/30">No players online.</div>
    </div>

    <div v-if="kickTarget" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3">
      <div class="text-[12.5px] font-medium">Kick {{ kickTarget.characterName || kickTarget.name }}</div>
      <input v-model="kickReason" placeholder="Reason" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
      <div class="flex gap-2">
        <button @click="kickTarget = null" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
        <button @click="submitKick" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Kick</button>
      </div>
    </div>
  </div>
</template>
