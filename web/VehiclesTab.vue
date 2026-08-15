<script setup>
import { ref, onMounted, onBeforeUnmount, inject, watch } from 'vue'
import Obelisk from '@/obelisk.js'

const vehicles = ref([])

const DEV_VEHICLES = [
  { id: 1, plate: 'ABC123', display_name: 'My Sultan', model: 'sultan', name: 'Sultan', owner_type: 'character', owner_id: 10, stored: 0, garage_id: null, fuel_level: 62, net_id: 4821 },
  { id: 2, plate: 'XYZ789', display_name: null, model: 'kuruma', name: 'Kuruma', owner_type: 'character', owner_id: 11, stored: 1, garage_id: 2, fuel_level: 100, net_id: null },
]

const onReply = ({ vehicles: next }) => { vehicles.value = next }

const fetchList = () => {
  if (import.meta.env.DEV) { vehicles.value = DEV_VEHICLES; return }
  Obelisk.emit('admin:client:vehicles-list', {})
}

onMounted(() => {
  Obelisk.on('admin:client:vehicles-reply', onReply)
  fetchList()
})
onBeforeUnmount(() => Obelisk.off('admin:client:vehicles-reply', onReply))

const registry = inject('obelisk:globalElementsRegistry', null)
if (registry) {
  watch(() => registry.get('admin')?.visible, (visible) => { if (visible) fetchList() })
}

const teleportToAdmin = (v) => Obelisk.emit('admin:client:vehicles-teleport-to-admin', { vehicleId: v.id })
const deleteVehicle = (v) => Obelisk.emit('admin:client:vehicles-delete', { vehicleId: v.id })
</script>

<template>
  <div class="flex-1 overflow-hidden flex flex-col p-5 gap-3">
    <div class="text-[12.5px] font-medium">Vehicles · {{ vehicles.length }}</div>
    <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex-1 overflow-y-auto">
      <div v-for="v in vehicles" :key="v.id" class="px-3.5 py-2.5 flex items-center gap-3 border-b border-white/6">
        <span class="w-2 h-8 rounded-full shrink-0" :style="{ background: v.net_id ? 'var(--ob-accent)' : 'rgba(255,255,255,.15)' }" :title="v.net_id ? 'Spawned' : 'Not spawned'" />
        <span class="min-w-0 flex-1">
          <span class="block text-[12px] truncate">{{ v.display_name || v.name }}</span>
          <span class="block ob-mono text-[9px] text-white/35 truncate">{{ v.plate || '—' }} · {{ v.name }} · owner {{ v.owner_type }}#{{ v.owner_id }}</span>
        </span>
        <button :disabled="!v.net_id" @click="teleportToAdmin(v)" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 hover:bg-white/8 disabled:opacity-30">GOTO</button>
        <button @click="deleteVehicle(v)" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 text-red-300 hover:bg-red-500/10">DELETE</button>
      </div>
      <div v-if="!vehicles.length" class="py-6 text-center text-[11.5px] text-white/30">No vehicles.</div>
    </div>
  </div>
</template>
