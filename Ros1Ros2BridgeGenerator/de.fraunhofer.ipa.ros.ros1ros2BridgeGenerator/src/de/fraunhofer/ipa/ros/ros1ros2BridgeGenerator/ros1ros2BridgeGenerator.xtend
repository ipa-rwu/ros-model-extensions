package de.fraunhofer.ipa.ros.ros1ros2BridgeGenerator

import ros.Node
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.generator.OutputConfiguration
import org.eclipse.xtext.generator.IOutputConfigurationProvider
import java.util.Set

//public class RosvalidatorExtra extends AbstractDeclarativeValidator {

class CustomOutputProvider implements IOutputConfigurationProvider {
	public final static String ROS1ROS2BRIDGE_GENERATOR_OUTPUT = "ROS1ROS2BRIDGE_GENERATOR_OUTPUT "
	
	override Set<OutputConfiguration> getOutputConfigurations() {
		var OutputConfiguration observer_config = new OutputConfiguration(ROS1ROS2BRIDGE_GENERATOR_OUTPUT )
		observer_config.setDescription("ROS1ROS2BRIDGE_GENERATOR_OUTPUT ");
		observer_config.setOutputDirectory("./src-gen/bridges/");
		observer_config.setOverrideExistingResources(true);
		observer_config.setCreateOutputDirectory(true);
		observer_config.setCleanUpDerivedResources(true);
		observer_config.setSetDerivedProperty(true);
		return newHashSet(observer_config)
	}
}

class ros1ros2BridgeGenerator extends AbstractGenerator {
	
	def void createXtextGenerationFolder (IFileSystemAccess2 fsa, IGeneratorContext context) {
		fsa.generateFile("lock",CustomOutputProvider::ROS1ROS2BRIDGE_GENERATOR_OUTPUT,'''''');
		fsa.deleteFile("lock",CustomOutputProvider::ROS1ROS2BRIDGE_GENERATOR_OUTPUT);
	}
	
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
			for (node : resource.allContents.toIterable.filter(Node)){
				fsa.generateFile(node.getName()+".cpp",CustomOutputProvider::ROS1ROS2BRIDGE_GENERATOR_OUTPUT,node.compile)
				}
			}

def compile(Node node) {
'''
// Copyright 2021 Fraunhofer IPA
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <iostream>
#include <memory>
#include <utility>

// include ROS 1
#ifdef __clang__
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunused-parameter"
#endif
#include "ros/ros.h"
            «FOR sub : node.subscriber»
#include <«sub.message.package.name»/«sub.message.name».h>
            «ENDFOR»
#ifdef __clang__
# pragma clang diagnostic pop
#endif

// include ROS 2
#include "rclcpp/rclcpp.hpp"
            «FOR sub : node.subscriber»
#include <«sub.message.package.name»/msg/«sub.message.name».hpp>
            «ENDFOR»

rclcpp::Publisher<std_msgs::msg::String>::SharedPtr pub;

void chatterCallback(const «FOR sub : node.subscriber»«sub.message.package.name»::«sub.message.name»::ConstPtr «ENDFOR»& ros1_msg)
{
  std::cout << "I heard: [" << ros1_msg->data << "]" << std::endl;
«FOR sub : node.subscriber»  auto ros2_msg = std::make_unique<«sub.message.package.name»::msg::«sub.message.name»>();«ENDFOR»
  ros2_msg->data = ros1_msg->data;
  std::cout << "Passing along: [" << ros2_msg->data << "]" << std::endl;
  pub->publish(std::move(ros2_msg));
}

int main(int argc, char * argv[])
{
  // ROS 2 node and publisher
  rclcpp::init(argc, argv);
  auto node = rclcpp::Node::make_shared("talker");
  pub = node->create_publisher<std_msgs::msg::String>("«node.subscriber.get(0).name»", 10);

  // ROS 1 node and subscriber
  ros::init(argc, argv, "listener");
  ros::NodeHandle n;
  ros::Subscriber sub = n.subscribe("«node.subscriber.get(0).name»", 10, chatterCallback);

  ros::spin();

  return 0;
}

'''
}

}