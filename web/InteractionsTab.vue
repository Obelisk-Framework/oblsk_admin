<script setup>
import { ref, computed, onMounted, onBeforeUnmount, inject, watch } from 'vue'
import Obelisk from '@/obelisk.js'

const activeSubTab = ref('plain')
// 'Plain' is always present; every other pill is rendered from whatever
// interaction types plugins have registered via core's InteractionTypeService
// (see interactionTypes below) -- oblsk_admin has no hardcoded knowledge of
// 'gasstation'/'mechanic' anymore.
const interactionTypes = ref([])
const SUB_TABS = computed(() => [['plain', 'Plain'], ...interactionTypes.value.map(t => [t.typeKey, t.label])])

const interactions = ref([])
const orgs = ref([])

// typeKey -> items[] for whichever type tabs have been fetched so far.
const typeItems = ref({})
const fuelTypes = ref([])

const selectedItemId = ref(null)
const activeType = computed(() => interactionTypes.value.find(t => t.typeKey === activeSubTab.value) || null)
const activeItems = computed(() => typeItems.value[activeSubTab.value] || [])
const selectedItem = computed(() => activeItems.value.find(i => i.id === selectedItemId.value) || null)

const plainCreateDraft = ref(null)
const typeCreateDraft = ref(null)
const stockDraft = ref({ fuelTypeId: '', pricePerLiter: 0, currentLiters: 0, maxLiters: 0 })

const round = (n) => (typeof n === 'number' ? Math.round(n * 10) / 10 : n)

const DEV_INTERACTIONS = [
  { id: 1, x: 100.1, y: 200.2, z: 30.3, range: 2.0, label: 'Old prompt', enabled: 1, attachedTo: 'other' },
]
const DEV_TYPES = [
  {
    typeKey: 'gasstation', label: 'Gas Station',
    fields: [
      { key: 'name', label: 'Name', type: 'text', required: true },
      { key: 'organizationId', label: 'Owner', type: 'organization' },
    ],
    blipRequirement: 'optional', pedRequirement: 'none', markerRequirement: 'optional',
  },
  {
    typeKey: 'mechanic', label: 'Mechanic Bay',
    fields: [
      { key: 'name', label: 'Name', type: 'text', required: true },
      { key: 'organizationId', label: 'Owner', type: 'organization' },
    ],
    blipRequirement: 'optional', pedRequirement: 'optional', markerRequirement: 'none',
  },
]
const DEV_TYPE_ITEMS = {
  gasstation: [
    { id: 1, name: 'Downtown Pump', organizationId: null, organizationName: null, interactionId: 2, x: 10, y: 20, z: 30, range: 2.0, label: 'Use pump', stock: [
      { id: 1, fuelTypeId: 1, fuelTypeName: 'Regular', pricePerLiter: 2.0, currentLiters: 500, maxLiters: 1000 },
    ] },
  ],
  mechanic: [
    { id: 1, name: 'Legion Bay', organizationId: null, organizationName: null, interactionId: 3, x: 40, y: 50, z: 60, range: 2.0, label: 'Drain tank' },
  ],
}
const DEV_FUEL_TYPES = [{ id: 1, name: 'Regular' }, { id: 2, name: 'Diesel' }]
const DEV_ORGS = [{ id: 1, name: 'City Works' }]

const onInteractionsReply = ({ interactions: next }) => { interactions.value = next }
const onTypesReply = ({ types: next }) => { interactionTypes.value = next }
const onTypeItemsReply = ({ typeKey, items }) => { typeItems.value = { ...typeItems.value, [typeKey]: items } }
const onFuelTypesReply = ({ fuelTypes: next }) => { fuelTypes.value = next }
const onOrgsReply = ({ orgs: next }) => { orgs.value = next }

const fetchAll = () => {
  if (import.meta.env.DEV) {
    interactions.value = DEV_INTERACTIONS
    interactionTypes.value = DEV_TYPES
    typeItems.value = DEV_TYPE_ITEMS
    fuelTypes.value = DEV_FUEL_TYPES
    orgs.value = DEV_ORGS
    return
  }
  Obelisk.emit('admin:client:interactions-list', {})
  Obelisk.emit('admin:client:interactionTypes-list', {})
  Obelisk.emit('admin:client:gasstation-fuelTypes-list', {})
  Obelisk.emit('admin:client:organisations-list', {})
}

const fetchTypeItems = (typeKey) => {
  if (import.meta.env.DEV) return
  Obelisk.emit('admin:client:interactionType-list', { typeKey })
}

onMounted(() => {
  Obelisk.on('admin:client:interactions-reply', onInteractionsReply)
  Obelisk.on('admin:client:interactionTypes-reply', onTypesReply)
  Obelisk.on('admin:client:interactionType-reply', onTypeItemsReply)
  Obelisk.on('admin:client:gasstation-fuelTypes-reply', onFuelTypesReply)
  Obelisk.on('admin:client:organisations-reply', onOrgsReply)
  fetchAll()
})
onBeforeUnmount(() => {
  Obelisk.off('admin:client:interactions-reply', onInteractionsReply)
  Obelisk.off('admin:client:interactionTypes-reply', onTypesReply)
  Obelisk.off('admin:client:interactionType-reply', onTypeItemsReply)
  Obelisk.off('admin:client:gasstation-fuelTypes-reply', onFuelTypesReply)
  Obelisk.off('admin:client:organisations-reply', onOrgsReply)
})

const registry = inject('obelisk:globalElementsRegistry', null)
if (registry) {
  watch(() => registry.get('admin')?.visible, (visible) => { if (visible) fetchAll() })
}

// Refetch a type tab's items whenever it's selected, mirroring the
// admin-visible refetch pattern above.
watch(activeSubTab, (key) => {
  if (key !== 'plain') fetchTypeItems(key)
})

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

// --- Generic interaction types ---
const defaultForField = (field) => (field.type === 'number' ? 0 : field.type === 'organization' || field.type === 'select' ? null : '')

const openTypeCreate = () => {
  const draft = { label: '', range: 2.0, x: 0, y: 0, z: 0 }
  for (const field of activeType.value?.fields || []) draft[field.key] = defaultForField(field)
  typeCreateDraft.value = draft
}
const submitTypeCreate = () => {
  Obelisk.emit('admin:client:interactionType-create', { typeKey: activeSubTab.value, fields: { ...typeCreateDraft.value } })
  typeCreateDraft.value = null
}
const updateTypeField = (field, value) => {
  Obelisk.emit('admin:client:interactionType-update', { typeKey: activeSubTab.value, id: selectedItem.value.id, fields: { [field]: value } })
}
const deleteTypeItem = () => {
  Obelisk.emit('admin:client:interactionType-delete', { typeKey: activeSubTab.value, id: selectedItem.value.id })
  selectedItemId.value = null
}

// --- Gas station fuel stock (special case, deliberately NOT generalized --
// see the comment on the stock sub-editor in the template below). ---
const addStock = () => {
  Obelisk.emit('admin:client:gasstation-stock-add', {
    stationId: selectedItem.value.id,
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
</script>

<template>
  <div class="min-h-0 p-5 flex flex-col gap-3">
    <div class="flex items-center gap-1">
      <button v-for="[key, label] in SUB_TABS" :key="key" @click="activeSubTab = key; selectedItemId = null"
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

    <!-- Generic type-driven tab (gasstation, mechanic, anything else a plugin registers) -->
    <div v-else-if="activeType" class="grid gap-3 min-h-0" style="grid-template-columns: 300px 1fr">
      <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex flex-col">
        <div class="px-4 py-2.5 border-b border-white/8 flex items-center justify-between">
          <span class="text-[12.5px] font-medium">{{ activeType.label }} · {{ activeItems.length }}</span>
          <button @click="openTypeCreate" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8">+ NEW</button>
        </div>
        <div class="overflow-y-auto" style="max-height: 520px">
          <button v-for="item in activeItems" :key="item.id" @click="selectedItemId = item.id; typeCreateDraft = null"
            class="w-full px-3.5 py-2.5 text-left border-b border-white/6 transition"
            :class="selectedItemId === item.id ? 'bg-white/[0.07]' : 'hover:bg-white/4'">
            <span class="block text-[12px] truncate">{{ item.name }}</span>
            <span class="block ob-mono text-[9px] text-white/35 truncate">{{ item.organizationName || 'Unowned' }} · {{ round(item.x) }}, {{ round(item.y) }}, {{ round(item.z) }}</span>
          </button>
          <div v-if="!activeItems.length" class="py-6 text-center text-[11.5px] text-white/30">Nothing yet.</div>
        </div>
      </div>

      <div v-if="typeCreateDraft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3 overflow-y-auto" style="max-height: 560px">
        <div class="text-[13px] font-medium">New {{ activeType.label.toLowerCase() }}</div>

        <div v-for="field in activeType.fields" :key="field.key">
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">{{ field.label }}</div>
          <select v-if="field.type === 'organization'" v-model="typeCreateDraft[field.key]" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none">
            <option :value="null">None (unowned)</option>
            <option v-for="o in orgs" :key="o.id" :value="o.id">{{ o.name }}</option>
          </select>
          <select v-else-if="field.type === 'select'" v-model="typeCreateDraft[field.key]" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none">
            <option :value="null">Select…</option>
            <option v-for="opt in field.options || []" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
          </select>
          <input v-else-if="field.type === 'number'" v-model.number="typeCreateDraft[field.key]" type="number" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
          <input v-else-if="field.type === 'boolean'" type="checkbox" v-model="typeCreateDraft[field.key]" class="h-4 w-4" />
          <input v-else v-model="typeCreateDraft[field.key]" :placeholder="field.label" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
        </div>

        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Prompt label</div>
          <input v-model="typeCreateDraft.label" placeholder="Prompt label" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
        </div>
        <input v-model.number="typeCreateDraft.range" type="number" step="0.5" placeholder="Range" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
        <div class="grid grid-cols-3 gap-1.5">
          <input v-model.number="typeCreateDraft.x" type="number" step="0.1" placeholder="X" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
          <input v-model.number="typeCreateDraft.y" type="number" step="0.1" placeholder="Y" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
          <input v-model.number="typeCreateDraft.z" type="number" step="0.1" placeholder="Z" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
        </div>
        <button @click="useMyPosition(typeCreateDraft)" class="w-full h-8 rounded-lg border border-white/12 text-[11px] hover:bg-white/8">Use my position</button>
        <div class="flex gap-2">
          <button @click="typeCreateDraft = null" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
          <button @click="submitTypeCreate" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Create</button>
        </div>
      </div>

      <div v-else-if="selectedItem" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3 overflow-y-auto" style="max-height: 560px">
        <div class="flex items-center gap-1.5 flex-wrap">
          <span class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 text-white/50">Blip: {{ activeType.blipRequirement }}</span>
          <span class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 text-white/50">Ped: {{ activeType.pedRequirement }}</span>
          <span class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 text-white/50">Marker: {{ activeType.markerRequirement }}</span>
        </div>

        <div v-for="field in activeType.fields" :key="field.key">
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">{{ field.label }}</div>
          <select v-if="field.type === 'organization'" :value="selectedItem[field.key]" @change="updateTypeField(field.key, $event.target.value ? Number($event.target.value) : null)"
            class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none">
            <option :value="null">None (unowned)</option>
            <option v-for="o in orgs" :key="o.id" :value="o.id">{{ o.name }}</option>
          </select>
          <select v-else-if="field.type === 'select'" :value="selectedItem[field.key]" @change="updateTypeField(field.key, $event.target.value)"
            class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none">
            <option v-for="opt in field.options || []" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
          </select>
          <input v-else-if="field.type === 'number'" :value="selectedItem[field.key]" @change="updateTypeField(field.key, Number($event.target.value))" type="number" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
          <input v-else :value="selectedItem[field.key]" @change="updateTypeField(field.key, $event.target.value)" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
        </div>

        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Coordinates</div>
          <div class="grid grid-cols-3 gap-1.5 mb-1.5">
            <input :value="selectedItem.x" @change="updateTypeField('x', Number($event.target.value))" type="number" step="0.1" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
            <input :value="selectedItem.y" @change="updateTypeField('y', Number($event.target.value))" type="number" step="0.1" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
            <input :value="selectedItem.z" @change="updateTypeField('z', Number($event.target.value))" type="number" step="0.1" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
          </div>
          <button @click="useMyPosition(selectedItem); updateTypeField('x', selectedItem.x); updateTypeField('y', selectedItem.y); updateTypeField('z', selectedItem.z)"
            class="w-full h-8 rounded-lg border border-white/12 text-[11px] hover:bg-white/8">Use my position</button>
        </div>

        <!-- Gas station fuel stock sub-editor - deliberately kept as a bespoke,
             typeKey==='gasstation'-only block rather than generalized into the
             fields schema above. A future "plugin-contributed rich sub-editor"
             system would be the right generalization, but with exactly one
             consumer today it isn't worth building yet - this is a scope trim,
             not an oversight. Wired to `selectedItem` (the generic list entry)
             instead of a bespoke gasstation-only list. -->
        <div v-if="activeSubTab === 'gasstation'" class="pt-2 border-t border-white/8">
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Fuel stock</div>
          <div v-for="stock in selectedItem.stock" :key="stock.id" class="flex items-center gap-1.5 mb-1.5">
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
          <button @click="deleteTypeItem" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 text-red-300 hover:bg-red-500/10">DELETE</button>
        </div>
      </div>
      <div v-else class="grid place-items-center text-white/30 text-[12px]">Nothing selected.</div>
    </div>
  </div>
</template>
