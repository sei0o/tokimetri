import { Controller } from "@hotwired/stimulus"

// 行のカテゴリの select まわり。log と inbox で使う
export default class extends Controller {
  colorize(event) {
    event.target.closest("tr").style.backgroundColor = event.target.selectedOptions[0].dataset.color || ""
  }

  // 自分で選んだら推測の印を外す。input はプログラムからの代入では飛ばない
  accept(event) {
    event.target.classList.remove("guessed")
  }

  // 空いているカテゴリを過去の記録から埋める。外していたら選び直せばいい
  async guess(event) {
    const select = event.target.closest("tr").querySelector("select.category")
    const what = event.target.value.trim()
    if (!select || select.value || !what) return

    const response = await fetch(`/category?what=${encodeURIComponent(what)}`)
    if (!response.ok) return

    const category = (await response.text()).trim()
    if (!category) return

    select.value = category
    if (select.value !== category) return

    select.classList.add("guessed")
    select.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
