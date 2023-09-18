
namespace :stripe do

  task report: :environment do

    # TODO: Get only active accounts

    Team.all.each do |team|
      puts "Team"

      all_stripe_accounts = team.integrations_stripe_installations
      all_stripe_accounts.each do |stripe_account|
        DigestJob.perform_later(stripe_account.id, team.id)
      end
    end

  end

end

