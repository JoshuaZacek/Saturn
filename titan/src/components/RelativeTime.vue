<script setup lang="ts">
import { computed } from 'vue'
import HoverTooltip from '@/components/HoverTooltip.vue'
import { useNow } from '@/composables/useNow'
import { formatPreciseTime, formatRelativeTime } from '@/utils/relativeTime'

// How long ago something happened ("5m ago"), kept up to date while the page is
// open. Hovering shows exactly when, in the reader's own time zone.
const props = defineProps<{
  datetime: string
}>()

const now = useNow()
const relative = computed(() => formatRelativeTime(props.datetime, now.value))
const precise = computed(() => formatPreciseTime(props.datetime))
</script>

<template>
  <HoverTooltip class="relativeTime" :text="precise">
    <time :datetime="datetime">{{ relative }}</time>
  </HoverTooltip>
</template>

<style scoped>
.relativeTime {
  white-space: nowrap;
}
</style>
