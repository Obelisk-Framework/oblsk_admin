<script setup>
import { ref, computed, onMounted, onBeforeUnmount, inject, watch } from 'vue'
import Obelisk from '@/obelisk.js'

const activeSubTab = ref('plain')
const SUB_TABS = [['plain', 'Plain'], ['gasstation', 'Gas Stations'], ['mechanic', 'Mechanic Bays']]

const interactions = ref([])
const gasStations = ref([])
const mechanicStations = ref([])
const fuelTypes = ref([])
const orgs = ref([])

const selectedGasId = ref(null)
const selectedMechanicId = ref(null)
const selectedGas = computed(() => gasStations.value.find(s => s.id === selectedGasId.value) || null)
const selectedMechanic = computed(() => mechanicStations.value.find(s => s.id === selectedMechanicId.value) || null)

const plainCreateDraft = ref(null)
const gasCreateDraft = ref(null)
const mechanicCreateDraft = ref(null)
const stockDraft = ref({ fuelTypeId: '', pricePerLiter: 0, currentLiters: 0, maxLiters: 0 })

const round = (n) => (typeof n === 'number' ? Math.round(n * 10) / 10 : n)

const DEV_INTERACTIONS = [
  { id: 1, x: 100.1, y: 200.2, z: 30.3, range: 2.0, label: 'Old prompt', enabled: 1, attachedTo: 'other' },
]
const DEV_GAS_STATIONS = [
  { id: 1, name: 'Downtown Pump', organizationId: null, organizationName: null, interactionId: 2, x: 10, y: 20, z: 30, range: 2.0, label: 'Use pump', stock: [
    { id: 1, fuelTypeId: 1, fuelTypeName: 'Regular', pricePerLiter: 2.0, currentLiters: 500, maxLiters: 1000 },
  ] },
]
const DEV_MECHANIC_STATIONS = [
  { id: 1, name: 'Legion Bay', organizationId: null, organizationName: null, interactionId: 3, x: 40, y: 50, z: 60, range: 2.0, label: 'Drain tank' },
]
const DEV_FUEL_TYPES = [{ id: 1, name: 'Regular' }, { id: 2, name: 'Diesel' }]
const DEV_ORGS = [{ id: 1, name: 'City Works' }]

const onInteractionsReply = ({ interactions: next }) => { interactions.value = next }
const onGasReply = ({ stations: next }) => { gasStations.value = next }
const onMechanicReply = ({ stations: next }) => { mechanicStations.value = next }
const onFuelTypesReply = ({ fuelTypes: next }) => { fuelTypes.value = next }
const onOrgsReply = ({ orgs: next }) => { orgs.value = next }

const fetchAll = () => {
  if (import.meta.env.DEV) {
    interactions.value = DEV_INTERACTIONS
    gasStations.value = DEV_GAS_STATIONS
    mechanicStations.value = DEV_MECHANIC_STATIONS
    fuelTypes.value = DEV_FUEL_TYPES
    orgs.value = DEV_ORGS
    return
  }
  Obelisk.emit('admin:client:interactions-list', {})
  Obelisk.emit('admin:client:gasstation-list', {})
  Obelisk.emit('admin:client:mechanic-list', {})
  Obelisk.emit('admin:client:gasstation-fuelTypes-list', {})
  Obelisk.emit('admin:client:organisations-list', {})
}

onMounted(() => {
  Obelisk.on('admin:client:interactions-reply', onInteractionsReply)
  Obelisk.on('admin:client:gasstation-reply', onGasReply)
  Obelisk.on('admin:client:mechanic-reply', onMechanicReply)
  Obelisk.on('admin:client:gasstation-fuelTypes-reply', onFuelTypesReply)
  Obelisk.on('admin:client:organisations-reply', onOrgsReply)
  fetchAll()
})
onBeforeUnmount(() => {
  Obelisk.off('admin:client:interactions-reply', onInteractionsReply)
  Obelisk.off('admin:client:gasstation-reply', onGasReply)
  Obelisk.off('admin:client:mechanic-reply', onMechanicReply)
  Obelisk.off('admin:client:gasstation-fuelTypes-reply', onFuelTypesReply)
  Obelisk.off('admin:client:organisations-reply', onOrgsReply)
})

const registry = inject('obelisk:globalElementsRegistry', null)
if (registry) {
  watch(() => registry.get('admin')?.visible, (visible) => { if (visible) fetchAll() })
}

// Captures the admin's current position via client/main.lua's
// 'admin:client:interactions-getMyCoords' handler and writes the reply
// into whichever draft object is passed - one-shot listener per call.
function useMyPosition(target) {
  if (import.meta.env.DEV) {
    target.x = 999.9; target.y = 888.8; target.z = 30.0
    return
  }
  const handler = ({ x, y, z }) => {
    target.x = x; target.y = y; target.z = z
    Obelisk.off('admin:client:interactions-myCoords', handler)
  }
  Obelisk.on('admin:client:interactions-myCoords', handler)
  Obelisk.emit('admin:client:interactions-getMyCoords', {})
}

// --- Plain interactions ---
const openPlainCreate = () => { plainCreateDraft.value = { label: '', range: 2.0, x: 0, y: 0, z: 0 } }
const submitPlainCreate = () => {
  Obelisk.emit('admin:client:interactions-create', { ...plainCreateDraft.value })
  plainCreateDraft.value = null
}
const toggleEnabled = (row) => {
  Obelisk.emit('admin:client:interactions-setEnabled', { id: row.id, enabled: row.enabled ? 0 : 1 })
}
const deleteInteraction = (row) => {
  Obelisk.emit('admin:client:interactions-delete', { id: row.id })
}

// --- Gas stations ---
const openGasCreate = () => { gasCreateDraft.value = { name: '', organizationId: null, label: '', range: 2.0, x: 0, y: 0, z: 0 } }
const submitGasCreate = () => {
  Obelisk.emit('admin:client:gasstation-create', { ...gasCreateDraft.value })
  gasCreateDraft.value = null
}
const updateGasField = (field, value) => {
  Obelisk.emit('admin:client:gasstation-update', { stationId: selectedGas.value.id, [field]: value })
}
const deleteGasStation = () => {
  Obelisk.emit('admin:client:gasstation-delete', { stationId: selectedGas.value.id })
  selectedGasId.value = null
}
const addStock = () => {
  Obelisk.emit('admin:client:gasstation-stock-add', {
    stationId: selectedGas.value.id,
    fuelTypeId: Number(stockDraft.value.fuelTypeId),
    pricePerLiter: Number(stockDraft.value.pricePerLiter),
    currentLiters: Number(stockDraft.value.currentLiters),
    maxLiters: Number(stockDraft.value.maxLiters),
  })
  stockDraft.value = { fuelTypeId: '', pricePerLiter: 0, currentLiters: 0, maxLiters: 0 }
}
const updateStockField = (stock, field, value) => {
  Obelisk.emit('admin:client:gasstation-stock-update', { stockId: stock.id, [field]: Number(value) })
}
const removeStock = (stock) => {
  Obelisk.emit('admin:client:gasstation-stock-remove', { stockId: stock.id })
}

// --- Mechanic bays ---
const openMechanicCreate = () => { mechanicCreateDraft.value = { name: '', organizationId: null, label: '', range: 2.0, x: 0, y: 0, z: 0 } }
const submitMechanicCreate = () => {
  Obelisk.emit('admin:client:mechanic-create', { ...mechanicCreateDraft.value })
  mechanicCreateDraft.value = null
}
const updateMechanicField = (field, value) => {
  Obelisk.emit('admin:client:mechanic-update', { stationId: selectedMechanic.value.id, [field]: value })
}
const deleteMechanicStation = () => {
  Obelisk.emit('admin:client:mechanic-delete', { stationId: selectedMechanic.value.id })
  selectedMechanicId.value = null
}
</script>

<template>
  <div class="min-h-0 p-5 flex flex-col gap-3">
    <div class="flex items-center gap-1">
      <button v-for="[key, label] in SUB_TABS" :key="key" @click="activeSubTab = key"
        class="px-3 py-1.5 rounded-lg text-[12px] transition"
        :class="activeSubTab === key ? 'text-black font-medium' : 'text-white/45 hover:text-white hover:bg-white/8'"
        :style="activeSubTab === key ? { background: 'var(--ob-accent)' } : undefined">
        {{ label }}
      </button>
    </div>

    <!-- Plain interactions -->
    <div v-if="activeSubTab === 'plain'" class="grid gap-3 min-h-0" style="grid-template-columns: 1fr 320px">
      <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex flex-col">
        <div class="px-4 py-2.5 border-b border-white/8 flex items-center justify-between">
          <span class="text-[12.5px] font-medium">Interactions · {{ interactions.length }}</span>
          <button @click="openPlainCreate" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8">+ NEW</button>
        </div>
        <div class="overflow-y-auto" style="max-height: 520px">
          <div v-for="row in interactions" :key="row.id" class="px-3.5 py-2.5 border-b border-white/6 flex items-center justify-between gap-2">
            <div class="min-w-0">
              <span class="block text-[12px] truncate">{{ row.label }}</span>
              <span class="block ob-mono text-[9px] text-white/35 truncate">{{ round(row.x) }}, {{ round(row.y) }}, {{ round(row.z) }} · r{{ row.range }}</span>
              <span class="block ob-mono text-[9px] text-white/30">{{ row.attachedTo === 'other' ? 'unattached' : '→ ' + row.attachedTo }}</span>
            </div>
            <div class="flex items-center gap-1.5 shrink-0">
              <button @click="toggleEnabled(row)" class="ob-mono text-[9px] px-1.5 py-1 rounded border"
                :class="row.enabled ? 'border-white/30 text-black font-medium' : 'border-white/12 text-white/40'"
                :style="row.enabled ? { background: 'var(--ob-accent)' } : undefined">{{ row.enabled ? 'ON' : 'OFF' }}</button>
              <button @click="deleteInteraction(row)"
                :title="row.attachedTo !== 'other' ? 'Delete the owning ' + row.attachedTo + ' station first' : ''"
                class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 text-red-300 hover:bg-red-500/10">DELETE</button>
            </div>
          </div>
          <div v-if="!interactions.length" class="py-6 text-center text-[11.5px] text-white/30">No interactions.</div>
        </div>
      </div>

      <div v-if="plainCreateDraft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3 self-start">
        <div class="text-[13px] font-medium">New interaction</div>
        <input v-model="plainCreateDraft.label" placeholder="Label" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
        <input v-model.number="plainCreateDraft.range" type="number" step="0.5" placeholder="Range" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
        <div class="grid grid-cols-3 gap-1.5">
          <input v-model.number="plainCreateDraft.x" type="number" step="0.1" placeholder="X" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
          <input v-model.number="plainCreateDraft.y" type="number" step="0.1" placeholder="Y" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
          <input v-model.number="plainCreateDraft.z" type="number" step="0.1" placeholder="Z" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
        </div>
        <button @click="useMyPosition(plainCreateDraft)" class="w-full h-8 rounded-lg border border-white/12 text-[11px] hover:bg-white/8">Use my position</button>
        <div class="flex gap-2">
          <button @click="plainCreateDraft = null" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
          <button @click="submitPlainCreate" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Create</button>
        </div>
      </div>
      <div v-else class="grid place-items-center text-white/30 text-[12px]">Select "+ NEW" to add a prompt point.</div>
    </div>

    <!-- Gas stations -->
    <div v-else-if="activeSubTab === 'gasstation'" class="grid gap-3 min-h-0" style="grid-template-columns: 300px 1fr">
      <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex flex-col">
        <div class="px-4 py-2.5 border-b border-white/8 flex items-center justify-between">
          <span class="text-[12.5px] font-medium">Pumps · {{ gasStations.length }}</span>
          <button @click="openGasCreate" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8">+ NEW STATION</button>
        </div>
        <div class="overflow-y-auto" style="max-height: 520px">
          <button v-for="s in gasStations" :key="s.id" @click="selectedGasId = s.id; gasCreateDraft = null"
            class="w-full px-3.5 py-2.5 text-left border-b border-white/6 transition"
            :class="selectedGasId === s.id ? 'bg-white/[0.07]' : 'hover:bg-white/4'">
            <span class="block text-[12px] truncate">{{ s.name }}</span>
            <span class="block ob-mono text-[9px] text-white/35 truncate">{{ s.organizationName || 'Unowned' }} · {{ round(s.x) }}, {{ round(s.y) }}, {{ round(s.z) }}</span>
          </button>
          <div v-if="!gasStations.length" class="py-6 text-center text-[11.5px] text-white/30">No stations.</div>
        </div>
      </div>

      <div v-if="gasCreateDraft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3">
        <div class="text-[13px] font-medium">New pump station</div>
        <input v-model="gasCreateDraft.name" placeholder="Name" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
        <input v-model="gasCreateDraft.label" placeholder="Prompt label" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
        <select v-model="gasCreateDraft.organizationId" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none">
          <option :value="null">None (unowned)</option>
          <option v-for="o in orgs" :key="o.id" :value="o.id">{{ o.name }}</option>
        </select>
        <input v-model.number="gasCreateDraft.range" type="number" step="0.5" placeholder="Range" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
        <div class="grid grid-cols-3 gap-1.5">
          <input v-model.number="gasCreateDraft.x" type="number" step="0.1" placeholder="X" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
          <input v-model.number="gasCreateDraft.y" type="number" step="0.1" placeholder="Y" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
          <input v-model.number="gasCreateDraft.z" type="number" step="0.1" placeholder="Z" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
        </div>
        <button @click="useMyPosition(gasCreateDraft)" class="w-full h-8 rounded-lg border border-white/12 text-[11px] hover:bg-white/8">Use my position</button>
        <div class="flex gap-2">
          <button @click="gasCreateDraft = null" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
          <button @click="submitGasCreate" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Create station</button>
        </div>
      </div>

      <div v-else-if="selectedGas" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3 overflow-y-auto" style="max-height: 560px">
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Name</div>
          <input :value="selectedGas.name" @change="updateGasField('name', $event.target.value)" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
        </div>
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Organisation</div>
          <select :value="selectedGas.organizationId" @change="updateGasField('organizationId', $event.target.value ? Number($event.target.value) : null)"
            class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none">
            <option :value="null">None (unowned)</option>
            <option v-for="o in orgs" :key="o.id" :value="o.id">{{ o.name }}</option>
          </select>
        </div>
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Coordinates</div>
          <div class="grid grid-cols-3 gap-1.5 mb-1.5">
            <input :value="selectedGas.x" @change="updateGasField('x', Number($event.target.value))" type="number" step="0.1" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
            <input :value="selectedGas.y" @change="updateGasField('y', Number($event.target.value))" type="number" step="0.1" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
            <input :value="selectedGas.z" @change="updateGasField('z', Number($event.target.value))" type="number" step="0.1" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
          </div>
          <button @click="useMyPosition(selectedGas); updateGasField('x', selectedGas.x); updateGasField('y', selectedGas.y); updateGasField('z', selectedGas.z)"
            class="w-full h-8 rounded-lg border border-white/12 text-[11px] hover:bg-white/8">Use my position</button>
        </div>

        <div class="pt-2 border-t border-white/8">
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Fuel stock</div>
          <div v-for="stock in selectedGas.stock" :key="stock.id" class="flex items-center gap-1.5 mb-1.5">
            <span class="text-[11px] w-16 truncate">{{ stock.fuelTypeName }}</span>
            <input :value="stock.pricePerLiter" @change="updateStockField(stock, 'pricePerLiter', $event.target.value)" type="number" step="0.01" title="Price/L" class="h-8 w-16 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[10px] outline-none" />
            <input :value="stock.currentLiters" @change="updateStockField(stock, 'currentLiters', $event.target.value)" type="number" step="1" title="Current L" class="h-8 w-16 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[10px] outline-none" />
            <input :value="stock.maxLiters" @change="updateStockField(stock, 'maxLiters', $event.target.value)" type="number" step="1" title="Max L" class="h-8 w-16 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[10px] outline-none" />
            <button @click="removeStock(stock)" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 text-red-300 hover:bg-red-500/10">X</button>
          </div>
          <div class="flex items-center gap-1.5 mt-2">
            <select v-model="stockDraft.fuelTypeId" class="h-8 px-2 rounded-lg bg-black/40 border border-white/12 text-[10px] outline-none flex-1">
              <option value="">Fuel type…</option>
              <option v-for="ft in fuelTypes" :key="ft.id" :value="ft.id">{{ ft.name }}</option>
            </select>
            <input v-model.number="stockDraft.pricePerLiter" type="number" step="0.01" placeholder="$/L" class="h-8 w-16 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[10px] outline-none" />
            <input v-model.number="stockDraft.currentLiters" type="number" step="1" placeholder="Cur" class="h-8 w-16 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[10px] outline-none" />
            <input v-model.number="stockDraft.maxLiters" type="number" step="1" placeholder="Max" class="h-8 w-16 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[10px] outline-none" />
            <button @click="addStock" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 hover:bg-white/8">ADD</button>
          </div>
        </div>

        <div class="pt-2">
          <button @click="deleteGasStation" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 text-red-300 hover:bg-red-500/10">DELETE STATION</button>
        </div>
      </div>
      <div v-else class="grid place-items-center text-white/30 text-[12px]">No station selected.</div>
    </div>

    <!-- Mechanic bays -->
    <div v-else class="grid gap-3 min-h-0" style="grid-template-columns: 300px 1fr">
      <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex flex-col">
        <div class="px-4 py-2.5 border-b border-white/8 flex items-center justify-between">
          <span class="text-[12.5px] font-medium">Bays · {{ mechanicStations.length }}</span>
          <button @click="openMechanicCreate" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8">+ NEW STATION</button>
        </div>
        <div class="overflow-y-auto" style="max-height: 520px">
          <button v-for="s in mechanicStations" :key="s.id" @click="selectedMechanicId = s.id; mechanicCreateDraft = null"
            class="w-full px-3.5 py-2.5 text-left border-b border-white/6 transition"
            :class="selectedMechanicId === s.id ? 'bg-white/[0.07]' : 'hover:bg-white/4'">
            <span class="block text-[12px] truncate">{{ s.name }}</span>
            <span class="block ob-mono text-[9px] text-white/35 truncate">{{ s.organizationName || 'Unowned' }} · {{ round(s.x) }}, {{ round(s.y) }}, {{ round(s.z) }}</span>
          </button>
          <div v-if="!mechanicStations.length" class="py-6 text-center text-[11.5px] text-white/30">No bays.</div>
        </div>
      </div>

      <div v-if="mechanicCreateDraft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3">
        <div class="text-[13px] font-medium">New mechanic bay</div>
        <input v-model="mechanicCreateDraft.name" placeholder="Name" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
        <input v-model="mechanicCreateDraft.label" placeholder="Prompt label" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
        <select v-model="mechanicCreateDraft.organizationId" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none">
          <option :value="null">None (unowned)</option>
          <option v-for="o in orgs" :key="o.id" :value="o.id">{{ o.name }}</option>
        </select>
        <input v-model.number="mechanicCreateDraft.range" type="number" step="0.5" placeholder="Range" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
        <div class="grid grid-cols-3 gap-1.5">
          <input v-model.number="mechanicCreateDraft.x" type="number" step="0.1" placeholder="X" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
          <input v-model.number="mechanicCreateDraft.y" type="number" step="0.1" placeholder="Y" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
          <input v-model.number="mechanicCreateDraft.z" type="number" step="0.1" placeholder="Z" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
        </div>
        <button @click="useMyPosition(mechanicCreateDraft)" class="w-full h-8 rounded-lg border border-white/12 text-[11px] hover:bg-white/8">Use my position</button>
        <div class="flex gap-2">
          <button @click="mechanicCreateDraft = null" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
          <button @click="submitMechanicCreate" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Create bay</button>
        </div>
      </div>

      <div v-else-if="selectedMechanic" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3">
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Name</div>
          <input :value="selectedMechanic.name" @change="updateMechanicField('name', $event.target.value)" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
        </div>
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Organisation</div>
          <select :value="selectedMechanic.organizationId" @change="updateMechanicField('organizationId', $event.target.value ? Number($event.target.value) : null)"
            class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none">
            <option :value="null">None (unowned)</option>
            <option v-for="o in orgs" :key="o.id" :value="o.id">{{ o.name }}</option>
          </select>
        </div>
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Coordinates</div>
          <div class="grid grid-cols-3 gap-1.5 mb-1.5">
            <input :value="selectedMechanic.x" @change="updateMechanicField('x', Number($event.target.value))" type="number" step="0.1" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
            <input :value="selectedMechanic.y" @change="updateMechanicField('y', Number($event.target.value))" type="number" step="0.1" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
            <input :value="selectedMechanic.z" @change="updateMechanicField('z', Number($event.target.value))" type="number" step="0.1" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
          </div>
          <button @click="useMyPosition(selectedMechanic); updateMechanicField('x', selectedMechanic.x); updateMechanicField('y', selectedMechanic.y); updateMechanicField('z', selectedMechanic.z)"
            class="w-full h-8 rounded-lg border border-white/12 text-[11px] hover:bg-white/8">Use my position</button>
        </div>
        <div class="pt-2">
          <button @click="deleteMechanicStation" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 text-red-300 hover:bg-red-500/10">DELETE STATION</button>
        </div>
      </div>
      <div v-else class="grid place-items-center text-white/30 text-[12px]">No bay selected.</div>
    </div>
  </div>
</template>
