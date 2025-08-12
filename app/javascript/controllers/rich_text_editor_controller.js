import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rich-text-editor"
export default class extends Controller {
  static targets = ["editor"]
  static values = { content: String }

  connect() {
    this.initializeEditor()
  }

  disconnect() {
    if (this.editor) {
      this.editor.destroy()
    }
  }

  async initializeEditor() {
    // For now, we'll use a simple rich textarea with formatting buttons
    // In production, you'd integrate with CKEditor or similar
    const editor = this.editorTarget
    
    // Add formatting toolbar
    const toolbar = document.createElement('div')
    toolbar.className = 'flex flex-wrap gap-1 p-2 border border-base-300 rounded-t-lg bg-base-100'
    toolbar.innerHTML = `
      <button type="button" class="btn btn-ghost btn-xs" data-action="click->rich-text-editor#bold" title="Bold">
        <strong>B</strong>
      </button>
      <button type="button" class="btn btn-ghost btn-xs" data-action="click->rich-text-editor#italic" title="Italic">
        <em>I</em>
      </button>
      <button type="button" class="btn btn-ghost btn-xs" data-action="click->rich-text-editor#underline" title="Underline">
        <u>U</u>
      </button>
      <div class="divider divider-horizontal"></div>
      <button type="button" class="btn btn-ghost btn-xs" data-action="click->rich-text-editor#insertList" title="Bullet List">
        • List
      </button>
      <button type="button" class="btn btn-ghost btn-xs" data-action="click->rich-text-editor#insertLink" title="Insert Link">
        Link
      </button>
    `
    
    // Insert toolbar before the editor
    editor.parentNode.insertBefore(toolbar, editor)
    
    // Style the editor
    editor.className += ' rounded-t-none'
    
    // Set initial content
    if (this.contentValue) {
      editor.value = this.contentValue
    }
  }

  bold() {
    this.wrapSelection('**', '**')
  }

  italic() {
    this.wrapSelection('*', '*')
  }

  underline() {
    this.wrapSelection('_', '_')
  }

  insertList() {
    this.insertAtCursor('\n• ')
  }

  insertLink() {
    const url = prompt('Enter URL:')
    if (url) {
      this.wrapSelection('[', `](${url})`)
    }
  }

  wrapSelection(before, after) {
    const editor = this.editorTarget
    const start = editor.selectionStart
    const end = editor.selectionEnd
    const selectedText = editor.value.substring(start, end)
    
    const newText = before + selectedText + after
    editor.value = editor.value.substring(0, start) + newText + editor.value.substring(end)
    
    // Reset cursor position
    editor.selectionStart = start + before.length
    editor.selectionEnd = start + before.length + selectedText.length
    editor.focus()
  }

  insertAtCursor(text) {
    const editor = this.editorTarget
    const start = editor.selectionStart
    
    editor.value = editor.value.substring(0, start) + text + editor.value.substring(start)
    editor.selectionStart = editor.selectionEnd = start + text.length
    editor.focus()
  }
}