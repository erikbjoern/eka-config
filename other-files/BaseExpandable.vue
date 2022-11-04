<template>
  <details :id="data.tagIds.details">
    <summary :id="data.tagIds.summary" @click="methods.animateDetailsElement">
      <slot name="summary" />
    </summary>
    <div :id="data.tagIds.content" class="content">
      <slot name="details" />
    </div>
  </details>
</template>

<script lang="ts">
import { nanoid } from 'nanoid'
import { onMounted, reactive, Ref, ref } from '@vue/composition-api'

/** Relevant documentation: https://developer.mozilla.org/en-US/docs/Web/API/Element/animate */

/**
 * @param animationRef - vue ref to the animation
 * @param animationStateRef - vue ref to the animation loading/ongoing state
 * @param beforeAnimationStart - callback to be called before animation start
 * @param element - the HTML element to animate
 * @param keyframes - array of JS objects containing the style values to transition between
 * @param onAnimationEnd - callback to be called when animation ends
 * @param options - animation options for duration, timing functions etc
 * @returns void
 */

export function animateElement(args: {
  animationRef: Ref<Animation>
  animationStateRef?: Ref<boolean>
  beforeAnimationStart: () => void
  element: HTMLElement
  keyframes: Keyframe[]
  onAnimationEnd: () => void
  options: KeyframeAnimationOptions
}) {
  const { animationRef, animationStateRef, element } = args

  if (animationRef.value) {
    animationRef.value.cancel()
  }
  safeInvoke(args.beforeAnimationStart)
  animationStateRef && (animationStateRef.value = true)

  /** Start an animation through Web Animations API
   *  and store a reference to it */
  animationRef.value = element.animate(args.keyframes, args.options)
  animationRef.value.oncancel = () => {
    animationStateRef && (animationStateRef.value = false)
  }
  animationRef.value.onfinish = () => {
    safeInvoke(args.onAnimationEnd)
    animationRef.value = null
    animationStateRef && (animationStateRef.value = false)
  }
}


export function safeInvoke(maybeCallback: () => void) {
  if (typeof maybeCallback === 'function') {
    return maybeCallback()
  }
}

/**
 * Relevant documentation:
 * https://developer.mozilla.org/en-US/docs/Web/HTML/Element/summary#usage_notes
 */

type DirectionSpecificAnimationArgs = {
  startHeight: number
  endHeight: number
  animationStateRef: Ref<boolean>
  onAnimationEnd?: () => void
  beforeAnimationStart?: () => void
}

export default {
  name: 'BaseExpandable',
  setup() {
    /** State of the component */
    const animation = ref<Animation>(null)
    const isClosing = ref(false)
    const isExpanding = ref(false)

    /** Keeping track of relevant HTML elements */
    const tagIds = {
      content: `content-${nanoid()}`,
      details: `details-${nanoid()}`,
      summary: `summary-${nanoid()}`,
    }
    const tags = reactive<{
      content: HTMLDivElement
      details: HTMLDetailsElement
      summary: HTMLDivElement
    }>({
      content: null,
      details: null,
      summary: null,
    })
    onMounted(() => {
      for (const tag in tags) {
        tags[tag] = document.getElementById(tagIds[tag])
      }
      tags.details.style.willChange = 'height'
    })

    /** Animation handlers */
    const getClosingAnimationArgs = (): DirectionSpecificAnimationArgs => ({
      animationStateRef: isClosing,
      beforeAnimationStart: () => (tags.details.dataset.isclosing = 'true'),
      onAnimationEnd: () => (tags.details.open = false),
      startHeight: tags.details.offsetHeight,
      endHeight: tags.summary.offsetHeight,
    })
    const getExpandingAnimationArgs = (): DirectionSpecificAnimationArgs => ({
      animationStateRef: isExpanding,
      beforeAnimationStart: () => (tags.details.open = true),
      startHeight: tags.summary.offsetHeight,
      endHeight: tags.summary.offsetHeight + tags.content.offsetHeight,
    })
    function forceResetAnimation() {
      if (animation.value) {
        animation.value.cancel()
      }
      isExpanding.value = false
      isClosing.value = false
    }
    function animateDetailsElement(e) {
      e.preventDefault()

      if (!tags.details) {
        console.error('BaseExpandable: No details tag found')
        return
      }

      const shouldClose = tags.details.open || isExpanding.value
      const shouldExpand = !tags.details.open || isClosing.value

      if ((!shouldClose && !shouldExpand) || (shouldClose && shouldExpand)) {
        console.warn('BaseExpandable: force-reset needed')
        return forceResetAnimation()
      }

      const animationArgs = shouldClose ? getClosingAnimationArgs() : getExpandingAnimationArgs()
      const heightDiff = Math.abs(animationArgs.endHeight - animationArgs.startHeight)
      const MIN_DURATION = 100

      /** set a explicit height to the element and request next frame before animating */
      tags.details.style.height = `${animationArgs.startHeight}px`
      requestAnimationFrame(() =>
        animateElement({
          ...animationArgs,
          element: tags.details as unknown as HTMLElement,
          animationRef: animation,
          beforeAnimationStart: () => {
            safeInvoke(animationArgs.beforeAnimationStart)
            tags.details.style.overflow = 'hidden'
          },
          onAnimationEnd: () => {
            safeInvoke(animationArgs.onAnimationEnd)
            tags.details.style.height = 'auto'
            tags.details.style.overflow = ''
            tags.details.dataset.isclosing = 'false'
          },
          keyframes: [
            { height: `${animationArgs.startHeight}px` },
            { height: `${animationArgs.endHeight}px` },
          ],
          options: {
            duration: Math.max(MIN_DURATION, Math.sqrt(heightDiff) * 10),
            easing: 'ease',
          },
        })
      )
    }

    return {
      data: reactive({
        tagIds,
      }),
      methods: reactive({
        animateDetailsElement,
      }),
    }
  },
}
</script>

<style scoped>
details summary::-webkit-details-marker {
  display: none;
}
details[open]:not([data-isclosing='true']) > summary:before {
  transform: rotate(90deg);
}

div.content {
  transition: opacity 100ms ease;
}
details[open='false'] div.content {
  opacity: 0;
}
details[open]:not([data-isclosing='true']) div.content {
  opacity: 1;
}
summary:before {
  content: '';
  border-width: 0.4rem;
  border-style: solid;
  border-color: transparent transparent transparent #f00;
  top: 1.3rem;
  left: 1rem;
  position: absolute;
  transform: rotate(0);
  transform-origin: 0.2rem 50%;
  transition: 0.125s transform ease;
}
summary {
  border: 4px solid transparent;
  outline: none;
  padding: 1rem;
  display: block;
  background: #444;
  color: white;
  padding-left: 2.2rem;
  position: relative;
  cursor: pointer;
}
</style>
