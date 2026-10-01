defmodule Cinder.Renderers.PaginationTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias Cinder.Renderers.Pagination

  defp build_theme do
    %{
      pagination_wrapper_class: "pagination-wrapper",
      pagination_container_class: "pagination-container",
      pagination_info_class: "pagination-info",
      pagination_count_class: "pagination-count",
      pagination_nav_class: "pagination-nav",
      pagination_button_class: "pagination-button",
      pagination_current_class: "pagination-current",
      page_size_container_class: "page-size-container",
      page_size_label_class: "page-size-label",
      page_size_dropdown_class: "page-size-dropdown",
      page_size_dropdown_container_class: "page-size-dropdown-container",
      page_size_option_class: "page-size-option",
      page_size_selected_class: "page-size-selected"
    }
  end

  defp base_assigns(id) do
    %{
      id: id,
      theme: build_theme(),
      page: %Ash.Page.Offset{
        results: [%{id: 1}, %{id: 2}],
        count: 100,
        offset: 0,
        limit: 10,
        more?: true
      },
      page_size_config: %{
        configurable: true,
        selected_page_size: 10,
        default_page_size: 10,
        page_size_options: [10, 25, 50]
      },
      myself: nil,
      show_pagination: true,
      pagination_mode: :offset
    }
  end

  describe "page size dropdown IDs" do
    test "dropdown ID is prefixed with table ID" do
      assigns = base_assigns("my-table")
      html = render_component(&Pagination.render/1, assigns)

      # The dropdown should have an ID prefixed with the table ID
      assert html =~ ~s(id="my-table-page-size-options")
    end

    test "different table IDs produce different dropdown IDs" do
      html1 = render_component(&Pagination.render/1, base_assigns("table-1"))
      html2 = render_component(&Pagination.render/1, base_assigns("table-2"))

      # Each table should have its own unique dropdown ID
      assert html1 =~ ~s(id="table-1-page-size-options")
      assert html2 =~ ~s(id="table-2-page-size-options")

      # They should NOT have the old hardcoded ID
      refute html1 =~ ~s(id="page-size-options")
      refute html2 =~ ~s(id="page-size-options")
    end

    test "JS toggle targets the correct prefixed ID" do
      assigns = base_assigns("users-table")
      html = render_component(&Pagination.render/1, assigns)

      # The toggle should target the prefixed ID
      assert html =~ ~s(#users-table-page-size-options)
    end
  end

  describe "pagination slot" do
    defp slot_assigns(page) do
      Map.merge(base_assigns("slot-table"), %{
        page: page,
        myself: "target",
        pagination_slot: [
          %{
            __slot__: :pagination_controls,
            inner_block: fn _changed, ctx ->
              "limit #{ctx.page.limit} of #{ctx.page.count}, " <>
                "size #{ctx.page_size_config.selected_page_size}, target #{ctx.target}"
            end
          }
        ]
      })
    end

    test "replaces the default controls inside the wrapper and receives the page" do
      html = render_component(&Pagination.render/1, slot_assigns(base_assigns("t").page))

      assert html =~ ~s(class="pagination-wrapper")
      assert html =~ "limit 10 of 100, size 10, target target"
      refute html =~ "pagination-nav"
      refute html =~ "page-size-container"
    end

    test "is not rendered when every result fits on one page" do
      page = %Ash.Page.Offset{results: [%{id: 1}], count: 1, offset: 0, limit: 10, more?: false}
      html = render_component(&Pagination.render/1, slot_assigns(page))

      refute html =~ "limit"
      refute html =~ "pagination-wrapper"
    end

    test "is not rendered when pagination is switched off" do
      assigns = Map.put(slot_assigns(base_assigns("t").page), :show_pagination, false)

      refute render_component(&Pagination.render/1, assigns) =~ "limit"
    end
  end
end
