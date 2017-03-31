class IntroductionComplete < Step
  self.icon = "celebrate"
  self.title = "Introduction"
  self.subhead = "It should take about 10 more minutes to complete a "\
    "full application."

  def initialize(*args)
    super
    self.headline = "Thank you #{@app.applicant.first_name}!"
  end

  def static_template
    "steps/introduction_complete"
  end

  def previous
    if @app.mailing_address_same_as_home_address
      IntroductionContactInformation.new(@app)
    else
      IntroductionHomeAddress.new(@app)
    end
  end

  def next
    HouseholdIntroduction.new(@app)
  end

  def assign_from_app
  end

  def update_app!
  end
end
