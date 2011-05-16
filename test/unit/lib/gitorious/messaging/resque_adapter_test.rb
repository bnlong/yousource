# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
require File.dirname(__FILE__) + '/../../../../messaging_test_helper'
require "gitorious/messaging"
#require "gitorious/messaging/resque_adapter"

class ResquePublisher
  include Gitorious::Messaging::Publisher
  include Gitorious::Messaging::ResqueAdapter::Publisher
end

class MessagingResqueAdapterTest < ActiveSupport::TestCase
  context "publisher" do
    should_map_resque_queues_to_processors(ResquePublisher) do
      { "/queue/GitoriousRepositoryCreation" => RepositoryCreationProcessor,
        "/queue/GitoriousRepositoryDeletion" => RepositoryDeletionProcessor,
        "/queue/GitoriousPush" => PushProcessor,
        "/queue/GitoriousSshKeys" => SshKeyProcessor,
        "/queue/GitoriousRepositoryArchiving" => RepositoryArchivingProcessor,
        "/queue/GitoriousEmailNotifications" => MessageForwardingProcessor,
        "/queue/GitoriousMergeRequestCreation" => MergeRequestProcessor,
        "/queue/GitoriousMergeRequestBackend" => MergeRequestGitBackendProcessor,
        "/queue/GitoriousMergeRequestVersionDeletion" => MergeRequestVersionProcessor,
        "/queue/GitoriousPostReceiveWebHook" => WebHookProcessor }
    end
  end
end
