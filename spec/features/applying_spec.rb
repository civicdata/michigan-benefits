require "rails_helper"

describe "applying", js: true do
  before do
    allow(FormMailer).to receive_message_chain(:submission, :deliver_now)
  end

  around(:each) do |example|
    with_modified_env FORM_RECIPIENT: 'test@example.com' do
      example.run
    end
  end

  specify do
    visit root_path
    click_on "Apply now"

    check_step "To start, please introduce yourself.",
               ["What is your first name?", "Alice", "Make sure to provide a first name"],
               ["What is your last name?", "Aardvark", "Make sure to provide a last name"]

    check_step "Tell us the best ways to reach you.",
               ["What is the best phone number to reach you?", "4158675309", "Make sure your phone number is 10 digits long"],
               ["May we send text messages to that phone number help you through the enrollment process?", "Yes", "Make sure to answer this question"],
               ["What is your email address?", "test@example.com", nil],
               ["Address", "123 Main St", "Make sure to answer this question"],
               ["City", "San Francisco", "Make sure to answer this question"],
               ["ZIP Code", "94110", "Make sure your ZIP code is 5 digits long"],
               ["Is this address the same as your home address?", "Yes", "Make sure to answer this question"]

    expect_page("It should take about 10 more minutes to complete a full application.")
    back

    expect_page("Tell us the best ways to reach you.")
    within_question("Is this address the same as your home address?") do
      choose "No"
    end
    submit

    check_step "Tell us where you currently live.",
      ["Street", "1234 Fake Street", "Make sure to answer this question"],
      ["City", "San Francisco", "Make sure to answer this question"],
      ["ZIP Code", "94110", "Make sure your ZIP code is 5 digits long"],
      ["Check if you do not have stable housing.", false, nil]

    static_step "It should take about 10 more minutes to complete a full application."
    static_step "There are 4 sections you need to complete to submit a full application."

    check_step "Provide us with some personal details.",
      ["What is your sex?", "Female", "Make sure to answer this question."],
      ["What is your marital status?", "Single", "Make sure to answer this question."],
      ["What is your social security number?", "123-45-6789", nil],
      ["How many people are in your household?", "3", nil]

    click_on "Add a household member"

    check_step "Tell us about another person you are applying with.",
      ["What is their first name?", "Cindy", nil],
      ["What is their last name?", "Crayfish", nil],
      ["What is their sex?", "Female", nil],
      ["What is their relationship to you?", "Child", nil],
      ["What is their social security number?", "444-44-4444", nil],
      ["Is this person living in your home?", "Yes", nil],
      ["Do you buy and prepare food with this person?", "Yes", nil],
      validations: false,
      verify: false

    click_on "Add a household member"

    check_step "Tell us about another person you are applying with.",
      ["What is their first name?", "Billy", nil],
      ["What is their last name?", "Bobcat", nil],
      ["What is their sex?", "Male", nil],
      ["What is their relationship to you?", "Sibling", nil],
      ["What is their social security number?", "555-55-5555", nil],
      ["Is this person living in your home?", "Yes", nil],
      ["Do you buy and prepare food with this person?", "Yes", nil],
      validations: false,
      verify: false

    submit

    check_step "Tell us a bit more about your household.",
      ["Is each person a citizen?", "No", nil],
      ["Does anyone have a disability?", "Yes", nil],
      ["Is anyone pregnant or has been pregnant recently?", "Yes", nil],
      ["Does anyone need help paying for recent medical bills?", "Yes", nil],
      ["Is anyone enrolled in college?", "Yes", nil],
      ["Is anyone temporarily living outside the home?", "Yes", nil]

    check_step "Ok, let us know which people these situations apply to.",
      ["Who is a citizen?", ["Billy"], nil],
      ["Who has a disability?", ["Cindy"], nil],
      ["Who is pregnant or has been pregnant recently?", ["Cindy"], nil],
      ["Who needs help paying for recent medical bills?", ["Alice"], nil],
      ["Who is enrolled in college?", ["Alice", "Billy"], nil],
      ["Who is temporarily living outside the home?", ["Alice", "Billy"], nil],
      validations: false

    check_step "Tell us about your household health coverage in the past 3 months.",
      ["Does anyone need help paying for medical bills from the past 3 months?", "No", "Make sure to answer this question"],
      ["Did anyone have insurance through a job and lose it in the last 3 months?", "No", "Make sure to answer this question"],
      validations: false

    expect_page "Ok, let us know which people these situations apply to."
    submit

    check_step "",
      ["Does anyone plan to file a federal tax return next year?", "No", "Make sure to answer this question"],
      validations: false

    expect_page "Describe how your household files taxes."
    submit

    expect_page "Next, describe your financial situation for us."
    submit

    check_step "Has your household had a change in income in the past 30 days?",
      ["Income change", "Yes", nil]

    check_step "In your own words, tell us about the recent change in your household's income.",
      ["Explanation", "I lost my job", nil],
      validations: false

    expect_page "Who in your household is currently employed, or has been in the past 30 days?"
    submit

    # check_step "Tell us more about your household's employment",
    #   ["Employer name", "Acme"],
    #   validations: false

    expect_page "Tell us more about your household's employment"
    submit

    check_step "Check all additional sources of income received by your household, if any.",
      ["Unemployment insurance", true, nil],
      ["SSI or Disability", false, nil],
      ["Worker's compensation", true, nil],
      ["Pension", false, nil],
      ["Social Security", true, nil],
      ["Child Support", false, nil],
      ["Foster Care or Adoption Subsidies", true, nil],
      ["Other income", false, nil],
      validations: false

    check_step "Tell us more about your additional income.",
      ["Monthly pay", "500", nil]

    check_step "Tell us about the assets and money you have on hand.",
      ["Does your household have any money or accounts?", "Yes", nil]

    check_step "Tell us more about those assets.",
      ["In total, how much money does your household have in cash and accounts?", "500", nil]

    expect_page "Next, describe your household expenses."
    submit
    back

    expect_page "Next, describe your household expenses."
    submit

    check_step "Tell us about your housing expenses.",
      ["How much does your household pay in rent or mortgage each month?", "300", "Make sure to answer this question"],
      ["How much do you pay in property tax each month?", "100", "Make sure to answer this question"],
      ["How much do you pay in insurance each month?", "20", "Make sure to answer this question"]

    expect(page).to have_text("Scroll down to agree")
    submit

    back
    expect_page "Scroll down to agree"
    submit

    check_step "Enter your full legal name here to sign this application.",
      ["Your signature", "Alice Aardvark", "Make sure you enter your signature"],
      verify: false

    check_doc_uploads

    click_on "I'm finished"

    expect_application_to_be_submitted
  end

  def expect_application_to_be_submitted
    expect(page).to have_text \
      "Your application has been successfully submitted."
  end

  def delete_first_attachment
    attachment = first('.attachment-preview')

    within attachment do
      click_on "Delete"
    end
  end

  def expect_page_to_have_attachments(count:)
    expect(page).to have_selector(".attachment-preview", count: count)
  end

  def upload_file(file)
    click_on "Add a document"

    attach_file "document_file", attachment_file_path(file)
    click_on "Upload"
  end

  def attachment_file_path(file)
    Rails.root.join("spec/fixtures/uploads/#{file}")
  end

  def check_doc_uploads
    click_on "Submit documents now"

    expect(page).to have_text("No documents uploaded yet.")

    upload_file("kermit.jpg")
    expect_page_to_have_attachments(count: 1)

    upload_file("oscar.jpg")
    expect_page_to_have_attachments(count: 2)

    delete_first_attachment
    expect_page_to_have_attachments(count: 1)

    upload_file("bad.txt")

    expect(page).to have_text("Invalid file type")

    back

    expect_page_to_have_attachments(count: 1)
  end
end
