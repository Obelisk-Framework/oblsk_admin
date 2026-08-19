<script setup>
import { ref, computed, onMounted, onBeforeUnmount, inject, watch } from 'vue'
import Obelisk from '@/obelisk.js'

const view = ref('catalog') // 'catalog' | 'owned'

//------------------------------------------------------------------
// Catalog (base_vehicles) -- the primary view, mirrors ItemsTab.vue's
// master-detail layout for base_items.
//------------------------------------------------------------------
const baseVehicles = ref([])
const fuelTypes = ref([])
const selectedId = ref(null)
const createDraft = ref(null)
const search = ref('')

const selected = computed(() => baseVehicles.value.find(v => v.id === selectedId.value) || null)
const filteredBaseVehicles = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return baseVehicles.value
  return baseVehicles.value.filter(v => (v.model || '').toLowerCase().includes(q) || (v.name || '').toLowerCase().includes(q))
})

const DEV_BASE_VEHICLES = [
  { id: 1, model: 'sultan', name: 'Sultan', has_trunk: 1, trunk_size: 40, trunk_slots: 10, has_glove_compartment: 1, glove_compartment_size: 5, glove_compartment_slots: 3, fuel_type_id: 1, fuel_type_name: 'petrol', tank_size: 65, fuel_consumption_rate: 1.0, seats: 4 },
  { id: 2, model: 'kuruma', name: 'Kuruma', has_trunk: 1, trunk_size: 30, trunk_slots: 8, has_glove_compartment: 0, glove_compartment_size: 0, glove_compartment_slots: 0, fuel_type_id: null, fuel_type_name: null, tank_size: 60, fuel_consumption_rate: 1.1, seats: 4 },
]
const DEV_FUEL_TYPES = [{ id: 1, name: 'petrol' }, { id: 2, name: 'diesel' }]

const onBaseVehiclesReply = ({ baseVehicles: next }) => { baseVehicles.value = next }
const onFuelTypesReply = ({ fuelTypes: next }) => { fuelTypes.value = next }

const fetchBaseVehicles = () => {
  if (import.meta.env.DEV) { baseVehicles.value = DEV_BASE_VEHICLES; return }
  Obelisk.emit('admin:client:baseVehicles-list', {})
}
const fetchFuelTypes = () => {
  if (import.meta.env.DEV) { fuelTypes.value = DEV_FUEL_TYPES; return }
  Obelisk.emit('admin:client:baseVehicles-fuelTypes-list', {})
}

const NUMBER_FIELDS = ['trunk_size', 'trunk_slots', 'glove_compartment_size', 'glove_compartment_slots', 'tank_size', 'fuel_consumption_rate', 'seats']
const CHECKBOX_FIELDS = ['has_trunk', 'has_glove_compartment']

const updateField = (baseVehicle, field, value) => {
  Obelisk.emit('admin:client:baseVehicles-update', { baseVehicleId: baseVehicle.id, attributes: { [field]: value } })
}
const onTextChange = (baseVehicle, field, event) => updateField(baseVehicle, field, event.target.value)
const onNumberChange = (baseVehicle, field, event) => updateField(baseVehicle, field, Number(event.target.value))
const onCheckboxChange = (baseVehicle, field, event) => updateField(baseVehicle, field, event.target.checked ? 1 : 0)
const onFuelTypeChange = (baseVehicle, event) => updateField(baseVehicle, 'fuel_type_id', event.target.value ? Number(event.target.value) : null)

const openCreate = () => {
  createDraft.value = {
    model: '', name: '',
    has_trunk: 0, trunk_size: 0, trunk_slots: 0,
    has_glove_compartment: 0, glove_compartment_size: 0, glove_compartment_slots: 0,
    fuel_type_id: null, tank_size: 0, fuel_consumption_rate: 1,
    seats: 4,
  }
}
const submitCreate = () => {
  Obelisk.emit('admin:client:baseVehicles-create', { attributes: createDraft.value })
  createDraft.value = null
}

const deleteBaseVehicle = (baseVehicle) => {
  Obelisk.emit('admin:client:baseVehicles-delete', { baseVehicleId: baseVehicle.id })
  if (selectedId.value === baseVehicle.id) selectedId.value = null
}

//------------------------------------------------------------------
// Owned instances (vehicles) -- unchanged functionality, moved to its
// own sub-tab so the catalog above can be the primary view.
//------------------------------------------------------------------
const vehicles = ref([])

const DEV_VEHICLES = [
  { id: 1, plate: 'ABC123', display_name: 'My Sultan', model: 'sultan', name: 'Sultan', owner_type: 'character', owner_id: 10, stored: 0, garage_id: null, fuel_level: 62, net_id: 4821 },
  { id: 2, plate: 'XYZ789', display_name: null, model: 'kuruma', name: 'Kuruma', owner_type: 'character', owner_id: 11, stored: 1, garage_id: 2, fuel_level: 100, net_id: null },
]

const onVehiclesReply = ({ vehicles: next }) => { vehicles.value = next }

const fetchVehicles = () => {
  if (import.meta.env.DEV) { vehicles.value = DEV_VEHICLES; return }
  Obelisk.emit('admin:client:vehicles-list', {})
}

const teleportToAdmin = (v) => Obelisk.emit('admin:client:vehicles-teleport-to-admin', { vehicleId: v.id })
const deleteVehicle = (v) => Obelisk.emit('admin:client:vehicles-delete', { vehicleId: v.id })

//------------------------------------------------------------------
// Lifecycle / refresh-on-open
//------------------------------------------------------------------
const fetchAll = () => { fetchBaseVehicles(); fetchFuelTypes(); fetchVehicles() }

onMounted(() => {
  Obelisk.on('admin:client:baseVehicles-reply', onBaseVehiclesReply)
  Obelisk.on('admin:client:baseVehicles-fuelTypes-reply', onFuelTypesReply)
  Obelisk.on('admin:client:vehicles-reply', onVehiclesReply)
  fetchAll()
})
onBeforeUnmount(() => {
  Obelisk.off('admin:client:baseVehicles-reply', onBaseVehiclesReply)
  Obelisk.off('admin:client:baseVehicles-fuelTypes-reply', onFuelTypesReply)
  Obelisk.off('admin:client:vehicles-reply', onVehiclesReply)
})

const registry = inject('obelisk:globalElementsRegistry', null)
if (registry) {
  watch(() => registry.get('admin')?.visible, (visible) => { if (visible) fetchAll() })
}
</script>

<template>
  <div class="flex-1 overflow-hidden flex flex-col p-5 gap-3">
    <div class="flex items-center gap-1.5">
      <button @click="view = 'catalog'" class="ob-mono text-[9px] px-2.5 py-1 rounded-lg border"
        :class="view === 'catalog' ? 'border-white/30 text-black font-medium' : 'border-white/12 text-white/40 hover:bg-white/8'"
        :style="view === 'catalog' ? { background: 'var(--ob-accent)' } : undefined">CATALOG</button>
      <button @click="view = 'owned'" class="ob-mono text-[9px] px-2.5 py-1 rounded-lg border"
        :class="view === 'owned' ? 'border-white/30 text-black font-medium' : 'border-white/12 text-white/40 hover:bg-white/8'"
        :style="view === 'owned' ? { background: 'var(--ob-accent)' } : undefined">OWNED INSTANCES</button>
    </div>

    <div v-if="view === 'catalog'" class="grid gap-3 min-h-0 flex-1" style="grid-template-columns: 300px 1fr">
      <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex flex-col">
        <div class="px-4 py-2.5 border-b border-white/8 flex items-center justify-between">
          <span class="text-[12.5px] font-medium">Vehicle models · {{ baseVehicles.length }}</span>
          <button @click="openCreate" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8">+ NEW</button>
        </div>
        <div class="px-3 py-2 border-b border-white/8">
          <input v-model="search" placeholder="Search model / name" class="w-full h-8 px-2.5 rounded-lg bg-black/40 border border-white/12 text-[11px] outline-none" />
        </div>
        <div class="overflow-y-auto flex-1">
          <button v-for="v in filteredBaseVehicles" :key="v.id" @click="selectedId = v.id; createDraft = null"
            class="w-full px-3.5 py-2.5 text-left border-b border-white/6 transition"
            :class="selectedId === v.id ? 'bg-white/[0.07]' : 'hover:bg-white/4'">
            <span class="block text-[12px] truncate">{{ v.name || v.model }}</span>
            <span class="block ob-mono text-[9px] text-white/35 truncate">{{ v.model }} · seats {{ v.seats ?? '—' }} · {{ v.fuel_type_name || 'no fuel type' }}</span>
          </button>
          <div v-if="!filteredBaseVehicles.length" class="py-6 text-center text-[11.5px] text-white/30">No vehicle models.</div>
        </div>
      </div>

      <div v-if="createDraft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3 overflow-y-auto">
        <div class="text-[13px] font-medium">New vehicle model</div>
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Model</div>
          <input v-model="createDraft.model" placeholder="e.g. sultan" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
        </div>
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Name</div>
          <input v-model="createDraft.name" placeholder="e.g. Sultan" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
        </div>
        <div class="grid grid-cols-2 gap-3">
          <label class="flex items-center gap-2 text-[11.5px]">
            <input type="checkbox" v-model="createDraft.has_trunk" true-value="1" false-value="0" class="h-4 w-4" />
            Has trunk
          </label>
          <label class="flex items-center gap-2 text-[11.5px]">
            <input type="checkbox" v-model="createDraft.has_glove_compartment" true-value="1" false-value="0" class="h-4 w-4" />
            Has glove compartment
          </label>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div v-for="field in NUMBER_FIELDS" :key="field">
            <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">{{ field.replace(/_/g, ' ') }}</div>
            <input v-model.number="createDraft[field]" type="number" step="any" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
          </div>
        </div>
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Fuel type</div>
          <select v-model="createDraft.fuel_type_id" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none">
            <option :value="null">None</option>
            <option v-for="ft in fuelTypes" :key="ft.id" :value="ft.id">{{ ft.name }}</option>
          </select>
        </div>
        <div class="flex gap-2">
          <button @click="createDraft = null" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
          <button @click="submitCreate" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Create vehicle model</button>
        </div>
      </div>

      <div v-else-if="selected" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3 overflow-y-auto">
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Model</div>
          <input :value="selected.model" @change="onTextChange(selected, 'model', $event)" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
        </div>
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Name</div>
          <input :value="selected.name" @change="onTextChange(selected, 'name', $event)" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
        </div>
        <div class="grid grid-cols-2 gap-3">
          <label v-for="flag in CHECKBOX_FIELDS" :key="flag" class="flex items-center gap-2 text-[11.5px]">
            <input type="checkbox" :checked="!!selected[flag]" @change="onCheckboxChange(selected, flag, $event)" class="h-4 w-4" />
            {{ flag.replace('has_', 'Has ').replace(/_/g, ' ') }}
          </label>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div v-for="field in NUMBER_FIELDS" :key="field">
            <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">{{ field.replace(/_/g, ' ') }}</div>
            <input :value="selected[field]" @change="onNumberChange(selected, field, $event)" type="number" step="any" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
          </div>
        </div>
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Fuel type</div>
          <select :value="selected.fuel_type_id" @change="onFuelTypeChange(selected, $event)" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none">
            <option :value="null">None</option>
            <option v-for="ft in fuelTypes" :key="ft.id" :value="ft.id">{{ ft.name }}</option>
          </select>
        </div>
        <div class="pt-2">
          <button @click="deleteBaseVehicle(selected)" class="h-9 px-4 rounded-lg text-[12px] font-medium border border-red-400/30 text-red-300 hover:bg-red-500/10">Delete vehicle model</button>
        </div>
      </div>

      <div v-else class="grid place-items-center text-white/30 text-[12px]">No vehicle model selected.</div>
    </div>

    <div v-else class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex-1 overflow-y-auto">
      <div class="px-4 py-2.5 border-b border-white/8 text-[12.5px] font-medium">Owned vehicles · {{ vehicles.length }}</div>
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
