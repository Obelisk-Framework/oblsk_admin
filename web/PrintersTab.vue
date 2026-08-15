<script setup>
import { ref, onMounted, onBeforeUnmount, inject, watch } from 'vue'
import Obelisk from '@/obelisk.js'

const printers = ref([])
const creating = ref(false)
const form = ref({ pos_x: 0, pos_y: 0, pos_z: 0, label: 'Printer', owner_auth: null, price_per_page: 2.0 })

const DEV_PRINTERS = [
  { id: 1, label: 'PD Front Desk', owner_auth: 'lspd', price_per_page: 0, range: 2, paper_level: 140, paper_capacity: 200, ink_level: 60, ink_capacity: 200 },
  { id: 2, label: 'Public Library', owner_auth: null, price_per_page: 2, range: 2, paper_level: 20, paper_capacity: 200, ink_level: 200, ink_capacity: 200 },
]

const onReply = ({ printers: next }) => { printers.value = next }

const fetchList = () => {
  if (import.meta.env.DEV) { printers.value = DEV_PRINTERS; return }
  Obelisk.emit('admin:client:printers-list', {})
}

onMounted(() => {
  Obelisk.on('admin:client:printers-reply', onReply)
  fetchList()
})
onBeforeUnmount(() => Obelisk.off('admin:client:printers-reply', onReply))

// Global elements use v-show and stay mounted for the webview's lifetime, so
// onMounted above only fires once (first NUI page load) -- refetch whenever
// this tab's global-element entry becomes visible again, same pattern as
// OrganisationsTab.vue/ItemsTab.vue, so the list can't go stale across an
// open/close/open cycle.
const registry = inject('obelisk:globalElementsRegistry', null)
if (registry) {
  watch(() => registry.get('admin')?.visible, (visible) => { if (visible) fetchList() })
}

function create() {
  Obelisk.emit('admin:client:printers-create', { ...form.value })
  creating.value = false
  form.value = { pos_x: 0, pos_y: 0, pos_z: 0, label: 'Printer', owner_auth: null, price_per_page: 2.0 }
}

function updateField(printer, field, value) {
  Obelisk.emit('admin:client:printers-update', { printerId: printer.id, [field]: value })
}

function remove(id) { Obelisk.emit('admin:client:printers-delete', { printerId: id }) }
function refill(id) { Obelisk.emit('admin:client:printers-refill', { printerId: id }) }
</script>

<template>
  <div class="flex-1 min-h-0 overflow-y-auto p-5">
    <div class="flex items-center justify-between mb-4">
      <div class="text-[13px] font-semibold">Printers</div>
      <button @click="creating = !creating" class="h-8 px-3 rounded-lg text-black text-[11.5px] font-medium" style="background: var(--ob-accent)">
        {{ creating ? 'Cancel' : 'New printer' }}
      </button>
    </div>

    <div v-if="creating" class="mb-4 p-3 rounded-lg border border-white/10 grid grid-cols-3 gap-2 text-[12px]">
      <input v-model.number="form.pos_x" placeholder="X" class="bg-black/30 rounded px-2 py-1" />
      <input v-model.number="form.pos_y" placeholder="Y" class="bg-black/30 rounded px-2 py-1" />
      <input v-model.number="form.pos_z" placeholder="Z" class="bg-black/30 rounded px-2 py-1" />
      <input v-model="form.label" placeholder="Label" class="bg-black/30 rounded px-2 py-1 col-span-2" />
      <select v-model="form.owner_auth" class="bg-black/30 rounded px-2 py-1">
        <option :value="null">Public</option>
        <option value="lspd">LSPD</option>
        <option value="lsmd">LSMD</option>
        <option value="doj">DOJ</option>
      </select>
      <input v-model.number="form.price_per_page" placeholder="Price / page" class="bg-black/30 rounded px-2 py-1" />
      <button @click="create" class="col-span-3 h-7 rounded bg-white/10 hover:bg-white/15 text-[11.5px]">Create</button>
    </div>

    <table class="w-full text-[12px]">
      <thead class="text-white/40 text-left">
        <tr><th class="pb-2">Label</th><th>Owner</th><th>Price/page</th><th>Paper</th><th>Ink</th><th></th></tr>
      </thead>
      <tbody>
        <tr v-for="p in printers" :key="p.id" class="border-t border-white/8">
          <td class="py-2">
            <input :value="p.label" @change="updateField(p, 'label', $event.target.value)"
              class="bg-transparent rounded px-1 py-0.5 w-full hover:bg-white/5 focus:bg-black/30 outline-none" />
          </td>
          <td>{{ p.owner_auth || 'Public' }}</td>
          <td>
            <input :value="p.price_per_page" type="number" step="0.5"
              @change="updateField(p, 'price_per_page', Number($event.target.value))"
              class="bg-transparent rounded px-1 py-0.5 w-16 hover:bg-white/5 focus:bg-black/30 outline-none" />
          </td>
          <td>{{ p.paper_level }}/{{ p.paper_capacity }}</td>
          <td>{{ p.ink_level }}/{{ p.ink_capacity }}</td>
          <td class="text-right space-x-2">
            <button @click="refill(p.id)" class="text-white/55 hover:text-white">Refill to full</button>
            <button @click="remove(p.id)" class="text-red-300/70 hover:text-red-300">Delete</button>
          </td>
        </tr>
        <tr v-if="!printers.length">
          <td colspan="6" class="py-6 text-center text-white/30">No printers.</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
