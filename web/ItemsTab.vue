<script setup>
import { ref, computed, onMounted, onBeforeUnmount, inject, watch } from 'vue'
import Obelisk from '@/obelisk.js'

const items = ref([])
const selectedId = ref(null)
const createDraft = ref(null)
const giveDraft = ref(null)

const bindings = ref([])
const requiredBindingKeys = ref([])
const newBindingKey = ref('')

const availableActions = ref([])
const actionPicker = ref('')

const uploadEndpoint = ref(null)
const iconUploading = ref(false)
const iconFileInput = ref(null)

const selected = computed(() => items.value.find(i => i.id === selectedId.value) || null)

const DEV_ITEMS = [
  { id: 1, name: 'water', description: 'A bottle of water', icon: 'water', weight: 0.5, is_takeable: 1, is_giveable: 1, is_dropable: 1, is_container: 0, is_useable: 1, is_stackable: 1, max_stack_amount: 10, actions: [{ action_id: 1, data: { text: 'Glug glug.' } }] },
  { id: 2, name: 'bandage', description: 'Stops bleeding', icon: 'bandage', weight: 0.2, is_takeable: 1, is_giveable: 1, is_dropable: 1, is_container: 0, is_useable: 1, is_stackable: 1, max_stack_amount: 5, actions: [] },
]
const DEV_BINDINGS = [{ id: 1, key: 'currency.cash', base_item_id: 1, base_item_name: 'water' }]
const DEV_REQUIRED_BINDING_KEYS = ['currency.cash', 'fishing.rod']
const DEV_ACTIONS = [
  { id: 1, action_id: 'item:notify', label: 'Drink' },
  { id: 2, action_id: 'item:consume_step', label: 'Consume one step' },
]

const onReply = ({ items: next }) => { items.value = next }

const fetchList = () => {
  if (import.meta.env.DEV) { items.value = DEV_ITEMS; return }
  Obelisk.emit('admin:client:items-list', {})
}

const onBindingsReply = ({ bindings: b, requiredKeys }) => { bindings.value = b; requiredBindingKeys.value = requiredKeys }
const fetchBindings = () => {
  if (import.meta.env.DEV) { bindings.value = DEV_BINDINGS; requiredBindingKeys.value = DEV_REQUIRED_BINDING_KEYS; return }
  Obelisk.emit('admin:client:items-bindings-list', {})
}

const onActionsReply = ({ actions }) => { availableActions.value = actions }
const fetchActions = () => {
  if (import.meta.env.DEV) { availableActions.value = DEV_ACTIONS; return }
  Obelisk.emit('admin:client:items-actions-list', {})
}

onMounted(() => {
  Obelisk.on('admin:client:items-reply', onReply)
  Obelisk.on('admin:client:items-bindings-reply', onBindingsReply)
  Obelisk.on('admin:client:items-actions-reply', onActionsReply)
  fetchList()
  fetchBindings()
  fetchActions()
})
onBeforeUnmount(() => {
  Obelisk.off('admin:client:items-reply', onReply)
  Obelisk.off('admin:client:items-bindings-reply', onBindingsReply)
  Obelisk.off('admin:client:items-actions-reply', onActionsReply)
})

const registry = inject('obelisk:globalElementsRegistry', null)
if (registry) {
  watch(() => registry.get('admin')?.visible, (visible) => { if (visible) { fetchList(); fetchBindings(); fetchActions() } })
}

watch(selectedId, () => { newBindingKey.value = ''; actionPicker.value = '' })

const FLAGS = ['is_useable', 'is_takeable', 'is_giveable', 'is_dropable', 'is_container', 'is_stackable']
const FLAG_LABELS = {
  is_useable: 'Usable',
  is_takeable: 'Can be taken',
  is_giveable: 'Can be traded',
  is_dropable: 'Can be dropped',
  is_container: 'Container',
  is_stackable: 'Stackable',
}

const categories = ref([])
const onCategoriesReply = ({ categories: next }) => { categories.value = next }
onMounted(() => { Obelisk.on('admin:client:categories-reply', onCategoriesReply); Obelisk.emit('admin:client:categories-list', {}) })
onBeforeUnmount(() => Obelisk.off('admin:client:categories-reply', onCategoriesReply))

const selectedCategory = computed(() => categories.value.find(c => c.id === selected.value?.base_item_category_id) || null)
const categoryFieldValues = ref({})
watch(() => [selected.value?.id, selectedCategory.value], ([, cat]) => {
  const data = selected.value?.data ? JSON.parse(selected.value.data) : {}
  categoryFieldValues.value = {}
  for (const f of (cat?.fields || [])) categoryFieldValues.value[f.name] = data[f.name] ?? ''
})

const setCategoryFieldValue = (name, value) => { categoryFieldValues.value[name] = value }
const saveCategoryData = () => {
  Obelisk.emit('admin:client:items-update-category-data', { baseItemId: selected.value.id, values: categoryFieldValues.value })
}

const updateField = (item, field, value) => {
  Obelisk.emit('admin:client:items-update', { baseItemId: item.id, attributes: { [field]: value } })
}

const onFlagChange = (item, flag, checked) => {
  const attributes = { [flag]: checked ? 1 : 0 }
  // "Can be taken" always implies "Can be traded" — mirrors the server-side
  // enforcement in ItemService.updateBaseItem, reflected here immediately so
  // the checkbox doesn't visually lag behind the next items-reply.
  if (flag === 'is_takeable' && checked) attributes.is_giveable = 1
  Obelisk.emit('admin:client:items-update', { baseItemId: item.id, attributes })
}

const openCreate = () => { createDraft.value = { name: '', description: '', weight: 0, max_stack_amount: 1, bindingKey: '' } }
const submitCreate = () => {
  const { bindingKey, ...attributes } = createDraft.value
  Obelisk.emit('admin:client:items-create', { attributes, bindingKey: bindingKey || null })
  createDraft.value = null
}

const openGive = (item) => { giveDraft.value = { item, targetSource: '', amount: 1 } }
const submitGive = () => {
  Obelisk.emit('admin:client:items-give', { targetSource: Number(giveDraft.value.targetSource), baseItemId: giveDraft.value.item.id, amount: Number(giveDraft.value.amount) })
  giveDraft.value = null
}

// --- Icon upload (Task 1) ---------------------------------------------

const isIconUrl = (icon) => typeof icon === 'string' && /^https?:\/\//.test(icon)

const ensureUploadEndpoint = () => new Promise((resolve) => {
  if (uploadEndpoint.value) { resolve(uploadEndpoint.value); return }
  const handler = ({ endpoint }) => {
    uploadEndpoint.value = endpoint
    Obelisk.off('admin:client:items-upload-endpoint', handler)
    resolve(endpoint)
  }
  Obelisk.on('admin:client:items-upload-endpoint', handler)
  Obelisk.emit('admin:client:items-get-upload-endpoint', {})
})

const mintIconUploadToken = (baseItemId) => new Promise((resolve) => {
  const handler = (payload) => {
    Obelisk.off('admin:client:items-icon-upload-token-reply', handler)
    resolve(payload)
  }
  Obelisk.on('admin:client:items-icon-upload-token-reply', handler)
  Obelisk.emit('admin:client:items-icon-upload-mint', { baseItemId })
})

const openIconPicker = () => iconFileInput.value?.click()

const onIconFileSelected = async (event) => {
  const file = event.target.files && event.target.files[0]
  event.target.value = ''
  if (!file || !selected.value) return
  const item = selected.value

  if (import.meta.env.DEV) {
    updateField(item, 'icon', 'https://placehold.co/128x128')
    return
  }

  iconUploading.value = true
  try {
    const endpoint = await ensureUploadEndpoint()
    const { token } = await mintIconUploadToken(item.id)
    const form = new FormData()
    form.append('token', token)
    form.append('files[]', file)
    const res = await fetch('https://' + endpoint + '/storage/upload', { method: 'POST', body: form })
    const { url } = await res.json()
    if (url) updateField(item, 'icon', url)
  } finally {
    iconUploading.value = false
  }
}

// --- Bindings (Task 2) --------------------------------------------------

const itemBindings = computed(() => bindings.value.filter(b => b.base_item_id === selectedId.value))
const missingRequiredBindingKeys = computed(() => requiredBindingKeys.value.filter(k => !bindings.value.some(b => b.key === k)))

const addBinding = (item) => {
  const key = newBindingKey.value.trim()
  if (!key) return
  Obelisk.emit('admin:client:items-bindings-set', { key, baseItemId: item.id })
  newBindingKey.value = ''
}
const clearBinding = (key) => Obelisk.emit('admin:client:items-bindings-clear', { key })

// --- Actions (Task 3) -----------------------------------------------------

const actionLabel = (actionDbId) => {
  const action = availableActions.value.find(a => a.id === actionDbId)
  return action ? (action.label || action.action_id) : ('#' + actionDbId)
}

const addAction = (item) => {
  if (!actionPicker.value) return
  const next = [...(item.actions || []), { action_id: Number(actionPicker.value), data: {} }]
  Obelisk.emit('admin:client:items-update-actions', { baseItemId: item.id, actions: next })
  actionPicker.value = ''
}
const removeAction = (item, index) => {
  const next = (item.actions || []).filter((_, i) => i !== index)
  Obelisk.emit('admin:client:items-update-actions', { baseItemId: item.id, actions: next })
}
const updateActionData = (item, index, text) => {
  let data
  try { data = JSON.parse(text || '{}') } catch { return }
  const next = (item.actions || []).map((a, i) => i === index ? { ...a, data } : a)
  Obelisk.emit('admin:client:items-update-actions', { baseItemId: item.id, actions: next })
}
</script>

<template>
  <div class="grid gap-3 min-h-0 p-5" style="grid-template-columns: 300px 1fr">
    <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex flex-col">
      <div class="px-4 py-2.5 border-b border-white/8 flex items-center justify-between">
        <span class="text-[12.5px] font-medium">Base item definitions · {{ items.length }}</span>
        <button @click="openCreate" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8">+ NEW</button>
      </div>
      <div class="overflow-y-auto" style="max-height: 520px">
        <button v-for="i in items" :key="i.id" @click="selectedId = i.id"
          class="w-full px-3.5 py-2.5 text-left border-b border-white/6 transition"
          :class="selectedId === i.id ? 'bg-white/[0.07]' : 'hover:bg-white/4'">
          <span class="block text-[12px] truncate">{{ i.name }}</span>
          <span class="block ob-mono text-[9px] text-white/35 truncate">{{ i.weight }}kg · stack {{ i.max_stack_amount || 1 }}</span>
        </button>
        <div v-if="!items.length" class="py-6 text-center text-[11.5px] text-white/30">No items.</div>
      </div>
    </div>

    <div v-if="createDraft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3">
      <div class="text-[13px] font-medium">New item</div>
      <input v-model="createDraft.name" placeholder="Name" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
      <input v-model="createDraft.description" placeholder="Description" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
      <input v-model.number="createDraft.weight" type="number" step="0.1" placeholder="Weight" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
      <input v-model="createDraft.bindingKey" placeholder="Binding key (optional, e.g. fishing.rod)" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
      <div class="flex gap-2">
        <button @click="createDraft = null" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
        <button @click="submitCreate" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Create item</button>
      </div>
    </div>

    <div v-else-if="selected" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-4 overflow-y-auto" style="max-height: 620px">
      <div>
        <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Description</div>
        <input :value="selected.description" @change="updateField(selected, 'description', $event.target.value)" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
      </div>

      <div>
        <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Icon</div>
        <div class="flex items-center gap-3">
          <div class="w-16 h-16 rounded-lg border border-white/12 bg-black/40 grid place-items-center overflow-hidden shrink-0">
            <img v-if="isIconUrl(selected.icon)" :src="selected.icon" class="w-full h-full object-cover" />
            <span v-else class="text-[9px] text-white/25 text-center px-1 leading-tight">No icon uploaded</span>
          </div>
          <div class="flex flex-col items-start gap-1.5">
            <span class="text-[10px] text-white/35">PNG or WEBP · 128×128</span>
            <button @click="openIconPicker" :disabled="iconUploading" class="h-8 px-3 rounded-lg border border-white/12 text-[11px] disabled:opacity-50">{{ iconUploading ? 'Uploading…' : 'Upload' }}</button>
            <input ref="iconFileInput" type="file" accept="image/png,image/webp" class="hidden" @change="onIconFileSelected" />
          </div>
        </div>
      </div>

      <div>
        <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Category</div>
        <select :value="selected.base_item_category_id" @change="updateField(selected, 'base_item_category_id', $event.target.value ? Number($event.target.value) : '__clear__')"
          class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none">
          <option :value="null">None</option>
          <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.name }}</option>
        </select>
      </div>

      <div v-if="selectedCategory" class="space-y-2">
        <div v-for="f in selectedCategory.fields" :key="f.name">
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1">{{ f.name }}{{ f.required ? ' *' : '' }}</div>
          <input v-if="f.type === 'text' || f.type === 'number'" :type="f.type" :value="categoryFieldValues[f.name]"
            @change="setCategoryFieldValue(f.name, $event.target.value)"
            class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
          <input v-else-if="f.type === 'boolean'" type="checkbox" :checked="!!categoryFieldValues[f.name]"
            @change="setCategoryFieldValue(f.name, $event.target.checked)" />
          <select v-else-if="f.type === 'select'" :value="categoryFieldValues[f.name]"
            @change="setCategoryFieldValue(f.name, $event.target.value)"
            class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none">
            <option v-for="opt in f.options" :key="opt" :value="opt">{{ opt }}</option>
          </select>
        </div>
        <button @click="saveCategoryData" class="h-8 px-3 rounded-lg text-black text-[11px] font-medium" style="background: var(--ob-accent)">Save category fields</button>
      </div>

      <div class="flex items-center justify-between py-1.5">
        <span class="ob-mono text-[10px] uppercase tracking-wide text-white/35">Kept after respawn</span>
        <button @click="updateField(selected, 'is_kept_after_respawn', selected.is_kept_after_respawn ? 0 : 1)"
          class="ob-mono text-[9px] px-2 py-1 rounded border"
          :class="selected.is_kept_after_respawn ? 'border-white/30 text-black font-medium' : 'border-white/12 text-white/40'"
          :style="selected.is_kept_after_respawn ? { background: 'var(--ob-accent)' } : undefined">
          {{ selected.is_kept_after_respawn ? 'YES' : 'NO' }}
        </button>
      </div>

      <div>
        <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Flags</div>
        <div class="space-y-1.5">
          <label v-for="flag in FLAGS" :key="flag" class="flex items-center gap-2 text-[11.5px] cursor-pointer">
            <input type="checkbox" class="h-4 w-4"
              :checked="!!selected[flag]"
              :disabled="flag === 'is_giveable' && !!selected.is_takeable"
              @change="onFlagChange(selected, flag, $event.target.checked)" />
            <span>{{ FLAG_LABELS[flag] }}</span>
          </label>
          <div v-if="selected.is_takeable" class="text-[10px] text-white/35 pl-6">Takeable items are always tradable</div>
        </div>
      </div>

      <div>
        <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Bindings</div>
        <div class="flex flex-wrap gap-1.5 mb-2">
          <span v-for="b in itemBindings" :key="b.key" class="ob-mono text-[9px] pl-2 pr-1 py-1 rounded border border-white/12 flex items-center gap-1.5">
            {{ b.key }}
            <button @click="clearBinding(b.key)" class="text-white/35 hover:text-white leading-none">✕</button>
          </span>
          <span v-if="!itemBindings.length" class="text-[10.5px] text-white/30">No bindings.</span>
        </div>
        <div class="flex gap-1.5">
          <input v-model="newBindingKey" placeholder="Binding key, e.g. currency.cash" class="flex-1 h-8 px-2.5 rounded-lg bg-black/40 border border-white/12 ob-mono text-[10.5px] outline-none" />
          <button @click="addBinding(selected)" class="h-8 px-3 rounded-lg border border-white/12 text-[11px]">Set</button>
        </div>
        <div v-if="missingRequiredBindingKeys.length" class="mt-1.5 flex flex-wrap items-center gap-1.5">
          <span class="text-[10px] text-white/30 w-full">Required by plugins, not yet set:</span>
          <button v-for="k in missingRequiredBindingKeys" :key="k" @click="newBindingKey = k" class="ob-mono text-[9px] px-2 py-0.5 rounded border border-white/12 text-white/40 hover:bg-white/6">{{ k }}</button>
        </div>
      </div>

      <div>
        <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Actions</div>
        <div class="space-y-1.5 mb-2">
          <div v-for="(a, i) in (selected.actions || [])" :key="i" class="flex items-center gap-1.5">
            <span class="text-[11px] flex-1 truncate">{{ actionLabel(a.action_id) }}</span>
            <input :value="JSON.stringify(a.data || {})" @change="updateActionData(selected, i, $event.target.value)" class="w-40 h-7 px-2 rounded bg-black/40 border border-white/12 ob-mono text-[9.5px] outline-none" />
            <button @click="removeAction(selected, i)" class="text-white/35 hover:text-white leading-none">✕</button>
          </div>
          <div v-if="!(selected.actions || []).length" class="text-[10.5px] text-white/30">No actions.</div>
        </div>
        <div class="flex gap-1.5">
          <select v-model="actionPicker" class="flex-1 h-8 px-2 rounded-lg bg-black/40 border border-white/12 text-[11px]">
            <option value="">Select action…</option>
            <option v-for="a in availableActions" :key="a.id" :value="a.id">{{ a.label || a.action_id }}</option>
          </select>
          <button @click="addAction(selected)" class="h-8 px-3 rounded-lg border border-white/12 text-[11px]">Add</button>
        </div>
      </div>

      <div class="pt-2">
        <button @click="openGive(selected)" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Give to player</button>
      </div>
    </div>

    <div v-else class="grid place-items-center text-white/30 text-[12px]">No item selected.</div>

    <div v-if="giveDraft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3 col-span-2">
      <div class="text-[13px] font-medium">Give {{ giveDraft.item.name }}</div>
      <input v-model="giveDraft.targetSource" placeholder="Player server ID" type="number" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
      <input v-model="giveDraft.amount" placeholder="Amount" type="number" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
      <div class="flex gap-2">
        <button @click="giveDraft = null" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
        <button @click="submitGive" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Give</button>
      </div>
    </div>
  </div>
</template>
