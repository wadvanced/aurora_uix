defmodule Aurora.Uix.Templates.Basic.Themes.Base do
  @behaviour Aurora.Uix.Theme

  def rule(:checkbox) do
    """
    .checkbox {
        appearance: none;
        padding: 0;
        display: inline-block;
        vertical-align: middle;
        flex-shrink: 0;
        height: 1rem;
        width: 1rem;
        border-width: 1px;
        border-style: solid;

        border-radius: 0.25rem;
        border-color: var(--color-border-default);
        background-color: var(--color-bg-white);
        color: var(--color-text-primary);


        --tw-ring-color: transparent;
        box-shadow: none;
        outline: none;
        background-image: none;
      }

      .checkbox:disabled {
        background-color: var(--color-bg-light);
        color: var(--color-text-secondary);

        opacity: 1;
        cursor: not-allowed;
      }
    """
  end

  def rule(:checkbox_label) do
    """
      .checkbox-label {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.875rem;
        line-height: 1.5rem;
        color: var(--color-text-secondary);
      }
    """
  end

  def rule(_), do: ""

end
