require "rails_helper"

RSpec.describe EmailApplicationJob do
  describe "#perform" do
    it "creates a PDF with the snap application data" do
      snap_application = create(:snap_application, :with_member)
      fake_mailer = double(deliver: nil)
      allow(ApplicationMailer).to receive(:snap_application_notification).
        and_return(fake_mailer)

      EmailApplicationJob.new.perform(snap_application_id: snap_application.id)

      expect(ApplicationMailer).to(
        have_received(:snap_application_notification).
          with(hash_including(recipient_email: snap_application.email)),
      )

      expect(fake_mailer).to have_received(:deliver)
    end
  end
end
