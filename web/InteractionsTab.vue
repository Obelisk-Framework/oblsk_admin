<script setup>
import { ref, computed, onMounted, onBeforeUnmount, inject, watch } from 'vue'
import Obelisk from '@/obelisk.js'

// Single unified list across every interaction type a plugin has registered
// via core's InteractionTypeService -- oblsk_admin has no hardcoded
// knowledge of 'gasstation'/'mechanic'/etc. There is no "plain"/bare
// interaction: every row always belongs to a registered strategy, created
// through that strategy's own create hook, and every row is always shown
// in the same searchable/filterable list rather than a per-type tab.
const interactionTypes = ref([])
const orgs = ref([])

// typeKey -> items[] for every registered type, fetched up front (not
// lazily per-tab like the old per-type-tab layout) so the unified list has
// everything to filter/search over as soon as the panel opens.
const typeItems = ref({})
const fuelTypes = ref([])

const searchQuery = ref('')
const typeFilter = ref(null) // null = all types

// Flattened, tagged with the type's own key/label so the list and detail
// panel can render/route without a lookup on every row.
const allItems = computed(() => {
  const out = []
  for (const type of interactionTypes.value) {
    for (const item of typeItems.value[type.typeKey] || []) {
      out.push({ ...item, typeKey: type.typeKey, typeLabel: type.label })
    }
  }
  return out
})

const filteredItems = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return allItems.value.filter(item => {
    if (typeFilter.value && item.typeKey !== typeFilter.value) return false
    if (!q) return true
    return (item.name || item.label || '').toLowerCase().includes(q)
  })
})

// Composite key -- item ids are only unique within their own type's table,
// not globally, so the selection/lookup key has to carry the type too.
const keyOf = (item) => `${item.typeKey}:${item.id}`
const selectedKey = ref(null)
const selectedItem = computed(() => allItems.value.find(i => keyOf(i) === selectedKey.value) || null)
const selectedType = computed(() => interactionTypes.value.find(t => t.typeKey === selectedItem.value?.typeKey) || null)

// null = closed, 'pickType' = choosing which strategy to create, or a
// typeKey once a strategy's been picked and its create form is showing.
const createStep = ref(null)
const typeCreateDraft = ref(null)
const stockDraft = ref({ fuelTypeId: '', pricePerLiter: 0, currentLiters: 0, maxLiters: 0 })

// --- Safe "linked stations" sub-editor state (bespoke, see the template
// block below) ---
const linkOwnerType = ref('')
const linkOwnerCandidates = ref([]) // items[] for whatever ownerType is currently picked
const linkOwnerId = ref('')

const round = (n) => (typeof n === 'number' ? Math.round(n * 10) / 10 : n)

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
  {
    typeKey: 'safe', label: 'Safe',
    fields: [
      { key: 'name', label: 'Name', type: 'text', required: true },
      { key: 'maxCash', label: 'Max cash', type: 'number' },
      { key: 'decayAmount', label: 'Decay/tick', type: 'number' },
    ],
    blipRequirement: 'none', pedRequirement: 'none', markerRequirement: 'optional',
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
  safe: [
    { id: 1, name: "Rob's Liquor — Back Safe", interactionId: 4, x: 12, y: 22, z: 30, range: 2.0, label: 'Open safe', maxCash: 15000, decayAmount: 50, owners: [
      { id: 1, ownerType: 'shop', ownerId: 1, ownerLabel: "Rob's Liquor" },
    ] },
  ],
}
const DEV_FUEL_TYPES = [{ id: 1, name: 'Regular' }, { id: 2, name: 'Diesel' }]
const DEV_ORGS = [{ id: 1, name: 'City Works' }]

const onTypesReply = ({ types: next }) => { interactionTypes.value = next }
const onTypeItemsReply = ({ typeKey, items }) => { typeItems.value = { ...typeItems.value, [typeKey]: items } }
const onFuelTypesReply = ({ fuelTypes: next }) => { fuelTypes.value = next }
const onOrgsReply = ({ orgs: next }) => { orgs.value = next }
const onSafeOwnerCandidatesReply = ({ ownerType, items }) => {
  if (ownerType !== linkOwnerType.value) return // stale reply for a since-changed picker
  linkOwnerCandidates.value = items
}

const fetchTypeItems = (typeKey) => {
  if (import.meta.env.DEV) return
  Obelisk.emit('admin:client:interactionType-list', { typeKey })
}

const fetchAll = () => {
  if (import.meta.env.DEV) {
    interactionTypes.value = DEV_TYPES
    typeItems.value = DEV_TYPE_ITEMS
    fuelTypes.value = DEV_FUEL_TYPES
    orgs.value = DEV_ORGS
    return
  }
  Obelisk.emit('admin:client:interactionTypes-list', {})
  Obelisk.emit('admin:client:gasstation-fuelTypes-list', {})
  Obelisk.emit('admin:client:organisations-list', {})
}

// As soon as the registered-type list arrives, pull every type's items up
// front -- the unified list/search needs all of them, not just whichever
// tab happened to be active (there are no tabs anymore).
watch(interactionTypes, (types) => {
  for (const type of types) fetchTypeItems(type.typeKey)
})

onMounted(() => {
  Obelisk.on('admin:client:interactionTypes-reply', onTypesReply)
  Obelisk.on('admin:client:interactionType-reply', onTypeItemsReply)
  Obelisk.on('admin:client:gasstation-fuelTypes-reply', onFuelTypesReply)
  Obelisk.on('admin:client:organisations-reply', onOrgsReply)
  Obelisk.on('admin:client:safe-ownerCandidates-reply', onSafeOwnerCandidatesReply)
  fetchAll()
})
onBeforeUnmount(() => {
  Obelisk.off('admin:client:interactionTypes-reply', onTypesReply)
  Obelisk.off('admin:client:interactionType-reply', onTypeItemsReply)
  Obelisk.off('admin:client:gasstation-fuelTypes-reply', onFuelTypesReply)
  Obelisk.off('admin:client:organisations-reply', onOrgsReply)
  Obelisk.off('admin:client:safe-ownerCandidates-reply', onSafeOwnerCandidatesReply)
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

function selectItem(item) {
  selectedKey.value = keyOf(item)
  createStep.value = null
  typeCreateDraft.value = null
}

// --- Create flow: pick a strategy first, then fill its form ---
const defaultForField = (field) => (field.type === 'number' ? 0 : field.type === 'organization' || field.type === 'select' ? null : '')

const openCreate = () => { createStep.value = 'pickType'; selectedKey.value = null }
const pickCreateType = (typeKey) => {
  const type = interactionTypes.value.find(t => t.typeKey === typeKey)
  const draft = { label: '', range: 2.0, x: 0, y: 0, z: 0 }
  for (const field of type?.fields || []) draft[field.key] = defaultForField(field)
  typeCreateDraft.value = draft
  createStep.value = typeKey
}
const cancelCreate = () => { createStep.value = null; typeCreateDraft.value = null }
const submitTypeCreate = () => {
  Obelisk.emit('admin:client:interactionType-create', { typeKey: createStep.value, fields: { ...typeCreateDraft.value } })
  cancelCreate()
}

// --- Generic interaction type mutations (selected item) ---
const updateTypeField = (field, value) => {
  Obelisk.emit('admin:client:interactionType-update', { typeKey: selectedItem.value.typeKey, id: selectedItem.value.id, fields: { [field]: value } })
}
const deleteTypeItem = () => {
  Obelisk.emit('admin:client:interactionType-delete', { typeKey: selectedItem.value.typeKey, id: selectedItem.value.id })
  selectedKey.value = null
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

// --- Safe "linked stations" sub-editor (special case, deliberately NOT
// generalized -- same posture as the gas station stock block above). Every
// OTHER registered interaction type is a valid owner type to link, `safe`
// itself excluded. ---
const linkableOwnerTypes = computed(() => interactionTypes.value.filter(t => t.typeKey !== 'safe'))
const onLinkOwnerTypeChange = () => {
  linkOwnerId.value = ''
  linkOwnerCandidates.value = []
  if (!linkOwnerType.value) return
  if (import.meta.env.DEV) {
    linkOwnerCandidates.value = DEV_TYPE_ITEMS[linkOwnerType.value] || []
    return
  }
  Obelisk.emit('admin:client:safe-ownerCandidates-list', { ownerType: linkOwnerType.value })
}
const linkOwner = () => {
  if (!linkOwnerType.value || !linkOwnerId.value) return
  Obelisk.emit('admin:client:safe-owners-link', {
    safeId: selectedItem.value.id,
    ownerType: linkOwnerType.value,
    ownerId: Number(linkOwnerId.value),
  })
  linkOwnerType.value = ''
  linkOwnerId.value = ''
  linkOwnerCandidates.value = []
}
const unlinkOwner = (owner) => {
  Obelisk.emit('admin:client:safe-owners-unlink', {
    safeId: selectedItem.value.id,
    ownerType: owner.ownerType,
    ownerId: owner.ownerId,
  })
}
</script>

<template>
  <div class="min-h-0 p-5 flex flex-col gap-3">
    <div class="grid gap-3 min-h-0" style="grid-template-columns: 340px 1fr">
      <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex flex-col">
        <div class="px-4 py-2.5 border-b border-white/8 flex items-center justify-between gap-2">
          <span class="text-[12.5px] font-medium">Interactions · {{ filteredItems.length }}</span>
          <button @click="openCreate" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8 shrink-0">+ NEW</button>
        </div>
        <div class="px-3 py-2 border-b border-white/8 flex gap-1.5">
          <input v-model="searchQuery" placeholder="Search…" class="flex-1 h-8 px-2.5 rounded-lg bg-black/40 border border-white/12 text-[11px] outline-none" />
          <select v-model="typeFilter" class="h-8 px-2 rounded-lg bg-black/40 border border-white/12 text-[10.5px] outline-none">
            <option :value="null">All types</option>
            <option v-for="t in interactionTypes" :key="t.typeKey" :value="t.typeKey">{{ t.label }}</option>
          </select>
        </div>
        <div class="overflow-y-auto" style="max-height: 520px">
          <button v-for="item in filteredItems" :key="keyOf(item)" @click="selectItem(item)"
            class="w-full px-3.5 py-2.5 text-left border-b border-white/6 transition"
            :class="selectedKey === keyOf(item) ? 'bg-white/[0.07]' : 'hover:bg-white/4'">
            <div class="flex items-center gap-1.5">
              <span class="ob-mono text-[8px] px-1.5 py-0.5 rounded border border-white/12 text-white/45 shrink-0">{{ item.typeLabel }}</span>
              <span class="text-[12px] truncate">{{ item.name || item.label }}</span>
            </div>
            <span class="block ob-mono text-[9px] text-white/35 truncate mt-0.5">{{ item.organizationName || 'Unowned' }} · {{ round(item.x) }}, {{ round(item.y) }}, {{ round(item.z) }}</span>
          </button>
          <div v-if="!filteredItems.length" class="py-6 text-center text-[11.5px] text-white/30">
            {{ allItems.length ? 'No matches.' : 'Nothing yet.' }}
          </div>
        </div>
      </div>

      <!-- Step 1 of create: pick which registered strategy this interaction belongs to. -->
      <div v-if="createStep === 'pickType'" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3 self-start">
        <div class="text-[13px] font-medium">New interaction — pick a type</div>
        <div v-if="!interactionTypes.length" class="text-[11.5px] text-white/40">No interaction types registered yet.</div>
        <div class="grid grid-cols-2 gap-2">
          <button v-for="t in interactionTypes" :key="t.typeKey" @click="pickCreateType(t.typeKey)"
            class="rounded-lg border border-white/12 p-3 text-left hover:bg-white/8 transition">
            <div class="text-[12.5px] font-medium">{{ t.label }}</div>
            <div class="ob-mono text-[8.5px] text-white/35 mt-1">Blip: {{ t.blipRequirement }} · Ped: {{ t.pedRequirement }} · Marker: {{ t.markerRequirement }}</div>
          </button>
        </div>
        <button @click="cancelCreate" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
      </div>

      <!-- Step 2 of create: the picked strategy's own field schema. -->
      <div v-else-if="typeCreateDraft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3 overflow-y-auto" style="max-height: 560px">
        <div class="text-[13px] font-medium">New {{ interactionTypes.find(t => t.typeKey === createStep)?.label.toLowerCase() }}</div>

        <div v-for="field in interactionTypes.find(t => t.typeKey === createStep)?.fields || []" :key="field.key">
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
          <button @click="cancelCreate" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
          <button @click="submitTypeCreate" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Create</button>
        </div>
      </div>

      <div v-else-if="selectedItem" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3 overflow-y-auto" style="max-height: 560px">
        <div class="flex items-center gap-1.5 flex-wrap">
          <span class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 text-white/60">{{ selectedType?.label }}</span>
          <span class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 text-white/50">Blip: {{ selectedType?.blipRequirement }}</span>
          <span class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 text-white/50">Ped: {{ selectedType?.pedRequirement }}</span>
          <span class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 text-white/50">Marker: {{ selectedType?.markerRequirement }}</span>
        </div>

        <div v-for="field in selectedType?.fields || []" :key="field.key">
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
          <div class="grid grid-cols-3 gap-1.5 mb-1 ob-mono text-[9px] text-white/35 text-center">
            <span>X</span><span>Y</span><span>Z</span>
          </div>
          <div class="grid grid-cols-3 gap-1.5 mb-1.5">
            <input :value="selectedItem.x" @change="updateTypeField('x', Number($event.target.value))" type="number" step="0.1" title="X" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
            <input :value="selectedItem.y" @change="updateTypeField('y', Number($event.target.value))" type="number" step="0.1" title="Y" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
            <input :value="selectedItem.z" @change="updateTypeField('z', Number($event.target.value))" type="number" step="0.1" title="Z" class="h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11px] outline-none" />
          </div>
          <button @click="useMyPosition(selectedItem); updateTypeField('x', selectedItem.x); updateTypeField('y', selectedItem.y); updateTypeField('z', selectedItem.z)"
            class="w-full h-8 rounded-lg border border-white/12 text-[11px] hover:bg-white/8">Use my position</button>
        </div>

        <!-- Gas station fuel stock sub-editor - deliberately kept as a bespoke,
             typeKey==='gasstation'-only block rather than generalized into the
             fields schema above. A future "plugin-contributed rich sub-editor"
             system would be the right generalization, but with exactly one
             consumer today it isn't worth building yet - this is a scope trim,
             not an oversight. -->
        <div v-if="selectedItem.typeKey === 'gasstation'" class="pt-2 border-t border-white/8">
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Fuel stock</div>
          <div class="flex items-center gap-1.5 mb-1 ob-mono text-[8.5px] text-white/35">
            <span class="w-16 shrink-0"></span>
            <span class="w-16 text-center">$/L</span>
            <span class="w-16 text-center">CURRENT L</span>
            <span class="w-16 text-center">MAX L</span>
          </div>
          <div v-for="stock in selectedItem.stock" :key="stock.id" class="flex items-center gap-1.5 mb-1.5">
            <span class="text-[11px] w-16 truncate">{{ stock.fuelTypeName }}</span>
            <input :value="stock.pricePerLiter" @change="updateStockField(stock, 'pricePerLiter', $event.target.value)" type="number" step="0.01" title="Price per liter" class="h-8 w-16 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[10px] outline-none" />
            <input :value="stock.currentLiters" @change="updateStockField(stock, 'currentLiters', $event.target.value)" type="number" step="1" title="Current liters in stock" class="h-8 w-16 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[10px] outline-none" />
            <input :value="stock.maxLiters" @change="updateStockField(stock, 'maxLiters', $event.target.value)" type="number" step="1" title="Max tank capacity in liters" class="h-8 w-16 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[10px] outline-none" />
            <button @click="removeStock(stock)" title="Remove this fuel type" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 text-red-300 hover:bg-red-500/10">X</button>
          </div>
          <div class="flex items-center gap-1.5 mt-2">
            <select v-model="stockDraft.fuelTypeId" title="Fuel type" class="h-8 px-2 rounded-lg bg-black/40 border border-white/12 text-[10px] outline-none flex-1">
              <option value="">Fuel type…</option>
              <option v-for="ft in fuelTypes" :key="ft.id" :value="ft.id">{{ ft.name }}</option>
            </select>
            <input v-model.number="stockDraft.pricePerLiter" type="number" step="0.01" placeholder="$/L" title="Price per liter" class="h-8 w-16 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[10px] outline-none" />
            <input v-model.number="stockDraft.currentLiters" type="number" step="1" placeholder="Cur L" title="Current liters in stock" class="h-8 w-16 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[10px] outline-none" />
            <input v-model.number="stockDraft.maxLiters" type="number" step="1" placeholder="Max L" title="Max tank capacity in liters" class="h-8 w-16 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[10px] outline-none" />
            <button @click="addStock" title="Add this fuel type to the station" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 hover:bg-white/8">ADD</button>
          </div>
        </div>

        <!-- Safe linked-stations sub-editor - deliberately kept as a bespoke,
             typeKey==='safe'-only block, same posture as the gas station
             fuel stock block above. Any linked owner can deposit its own
             point-of-sale revenue into this safe (see oblsk_safe). -->
        <div v-if="selectedItem.typeKey === 'safe'" class="pt-2 border-t border-white/8">
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Linked stations</div>
          <div v-if="!selectedItem.owners?.length" class="text-[11px] text-white/35 mb-2">No linked stations yet.</div>
          <div v-for="owner in selectedItem.owners" :key="owner.id" class="flex items-center gap-1.5 mb-1.5">
            <span class="ob-mono text-[8px] px-1.5 py-0.5 rounded border border-white/12 text-white/45 shrink-0">{{ owner.ownerType }}</span>
            <span class="text-[11px] flex-1 truncate">{{ owner.ownerLabel }}</span>
            <button @click="unlinkOwner(owner)" title="Unlink this station" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 text-red-300 hover:bg-red-500/10">X</button>
          </div>
          <div class="flex items-center gap-1.5 mt-2">
            <select v-model="linkOwnerType" @change="onLinkOwnerTypeChange" title="Owner type" class="h-8 px-2 rounded-lg bg-black/40 border border-white/12 text-[10px] outline-none flex-1">
              <option value="">Type…</option>
              <option v-for="t in linkableOwnerTypes" :key="t.typeKey" :value="t.typeKey">{{ t.label }}</option>
            </select>
            <select v-model="linkOwnerId" title="Station" class="h-8 px-2 rounded-lg bg-black/40 border border-white/12 text-[10px] outline-none flex-1">
              <option value="">Station…</option>
              <option v-for="c in linkOwnerCandidates" :key="c.id" :value="c.id">{{ c.name || c.label }}</option>
            </select>
            <button @click="linkOwner" title="Link this station to the safe" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 hover:bg-white/8">LINK</button>
          </div>
        </div>

        <div class="pt-2">
          <button @click="deleteTypeItem" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 text-red-300 hover:bg-red-500/10">DELETE</button>
        </div>
      </div>
      <div v-else class="grid place-items-center text-white/30 text-[12px]">Select an interaction, or "+ NEW" to add one.</div>
    </div>
  </div>
</template>
