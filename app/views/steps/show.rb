class Views::Steps::Show < Views::Base
  needs :step

  def content
    content_for :header_title, header_title

    step_form
  end

  private

  def header_title
    title = step.title

    if Rails.env.development?
      title += " <code style='opacity: 0.5'>(#{step.class.name})</code>"
    end

    title.html_safe
  end

  def render_static_content?
    step.static_template.present?
  end

  def step_form
    div class: 'form-card' do
      form_for step, as: :step, url: step_path(step), method: :put do |f|
        header class: 'form-card__header' do
          section_header
        end

        if render_static_content?
          div class: 'form-card__content' do
            render step.static_template
          end
        else
          div class: 'form-card__content' do
            questions(f)
          end
        end

        if step.previous.present? or step.next.present?
          footer class: 'form-card__footer' do
            buttons
          end
        end
      end
    end
  end

  def section_header
    div class: 'step-section-header' do
      if step.icon.present?
        div class: [
          "step-section-header__icon",
          "illustration",
          "illustration--#{step.icon}"
        ]
      end

      subhead_classes = "step-section-header__subhead"

      if step.only_subhead?
        subhead_classes += " step-section-header__subhead--standalone"
      end

      h4 step.headline, class: "step-section-header__headline"
      h3 step.subhead, class: subhead_classes
    end
  end

  def questions(f)
    step.questions.each do |question, label_text|
      group_classes = 'form-group'

      if step.errors[question].present?
        group_classes += ' form-group--error'
      end

      field_type = step.type(question)

      div class: group_classes, 'data-field-type' => field_type do
        if step.section_header(question)
          h4 step.section_header(question), class: "form-group__headline"
        end

        if step.overview(question)
          p step.overview(question)
        end

        case field_type
          when :text
            f.label question, label_text, class: 'form-question'

            f.text_field question,
              placeholder: step.placeholder(question),
              class: 'text-input'
          when :yes_no
            f.label question, label_text, class: 'form-question'

            div do
              label class: "radio-button" do
                f.radio_button question, "true"
                text "Yes"
              end

              label class: "radio-button" do
                f.radio_button question, "false"
                text "No"
              end
            end
          when :checkbox
            label class: "checkbox" do
              f.check_box question
              text label_text
            end
          else
            raise "Unknown field type #{field_type}"
        end

        if step.errors[question].present?
          p class: 'text--error' do
            i class: 'icon-warning'
            text " #{step.errors[question].to_sentence}"
          end
        end
      end
    end
  end

  def buttons
    if step.previous.present?
      link_to path_to_step(step.previous), class: "button button--secondary-cta" do
        i class: "button__icon icon-arrow_back"
        text "Back"
      end
    end

    if step.next.present?
      button type: 'submit', class: "button button--cta" do
        text step.submit_label
        i class: "button__icon icon-arrow_forward"
      end
    end

  end
end