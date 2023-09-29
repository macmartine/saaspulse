class Account::ApplicationController < ApplicationController
  include Account::Controllers::Base

  def ensure_onboarding_is_complete
    # First check that Bullet Train doesn't have any onboarding steps it needs to enforce.
    return false unless super

    # Most onboarding steps you'll add should be skipped if the user is adding a team or accepting an invitation ...
    unless adding_team? || accepting_invitation?
      # So, if you have new onboarding steps to check for an enforce, do that here:

      if current_user.details_provided? && !has_stripe_installations?
        if adding_stripe_integrations?
          return true
        else
          redirect_to account_team_integrations_stripe_installations_path(current_user.current_team.id)
          return false
        end
      end
    end

    # Finally, if we've gotten this far, then onboarding appears to be complete!
    true
  end

  def has_stripe_installations?
    current_user.current_team.integrations_stripe_installations.present?
  end

  def adding_stripe_integrations?
    is_a?(Account::Integrations::StripeInstallationsController)
  end

end
